-- Implementar un servicio que cree un nuevo usuario en el sistema. Esto implica inicializar al asistente
-- virtual con rol amigo y su respectiva configuración predeterminada (apariencia). Aquella información
-- que no se puede obtener de forma predeterminada se podrá enviar al servicio por parámetro.

CREATE OR REPLACE PROCEDURE crear_usuario (
    p_correo_electronico IN VARCHAR2,
    p_nombre IN VARCHAR2,
    p_contrasena IN VARCHAR2,
    p_id_pais IN NUMBER,
    p_fecha_nacimiento IN DATE,
    p_rango_edad IN VARCHAR2,
    p_genero IN CHAR,
    p_telefono IN VARCHAR2,
    p_version IN VARCHAR2,
    p_id_apariencia_predeterminada IN NUMBER
) IS
    v_id_usuario NUMBER;
    v_id_asistente NUMBER;
BEGIN
    -- Insertar el nuevo usuario
    INSERT INTO USUARIOS (
        correo_electronico, nombre, contraseña, id_pais, fecha_nacimiento, rango_edad, genero, telefono, version
    ) VALUES (
        p_correo_electronico, p_nombre, p_contrasena, p_id_pais, p_fecha_nacimiento, p_rango_edad, p_genero, p_telefono, p_version
    ) RETURNING id_usuario INTO v_id_usuario;

    -- Crear un asistente virtual asociado al nuevo usuario
    INSERT INTO ASISTENTES_VIRTUALES (
        id_usuario, nombre_asistente, genero_asistente, descripcion
    ) VALUES (
        v_id_usuario, 'Asistente Predeterminado', 'NB', 'Asistente inicial con configuración predeterminada'
    ) RETURNING id_asistente INTO v_id_asistente;

    -- Asignar el rol 'AMIGO' al asistente virtual
    INSERT INTO ASISTENTE_ROLES (
        id_asistente, nombre_rol
    ) VALUES (
        v_id_asistente, 'AMIGO'
    );

    -- Asignar la configuración predeterminada de apariencia al asistente
    INSERT INTO CONFIGURACIONES_APARIENCIAS (
        id_asistente, id_producto, seleccionado
    ) VALUES (
        v_id_asistente, p_id_apariencia_predeterminada, 1
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20008, 'Ocurrió un error al crear el usuario y su configuración: ' || SQLERRM);
END;


-- Elaborar un servicio que permita efectuar la compra de una prenda de ropa para el asistente virtual de
-- un determinado usuario. Tener en cuenta que si el usuario posee una suscripción Replika Pro activa
-- se le debe aplicar un descuento del 15 %.

CREATE OR REPLACE PROCEDURE comprar_ropa_asistente (
    p_id_usuario IN NUMBER,
    p_id_producto IN NUMBER,
    p_id_asistente IN NUMBER
) IS
    v_precio_original NUMBER;
    v_precio_final NUMBER;
    v_tiene_suscripcion NUMBER;
BEGIN
    -- Verificar si el producto es una prenda de ropa
    SELECT PRECIO INTO v_precio_original
    FROM PRODUCTOS
    WHERE ID_PRODUCTO = p_id_producto AND ID_TIPO_PRODUCTO = (SELECT ID_TIPO_PRODUCTO FROM TIPOS_PRODUCTO WHERE TIPO_PRODUCTO = 'ROPA');

    IF v_precio_original IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'El producto especificado no es una prenda de ropa válida.');
    END IF;

    -- Verificar si el usuario tiene una suscripción activa 'Replika Pro'
    SELECT COUNT(*) INTO v_tiene_suscripcion
    FROM SUSCRIPCIONES
    WHERE ID_USUARIO = p_id_usuario
      AND TIPO = '12 MESES'
      AND FECHA_VENCIMIENTO > SYSDATE;

    -- Calcular el precio final con descuento si tiene suscripción activa
    IF v_tiene_suscripcion > 0 THEN
        v_precio_final := v_precio_original * 0.85; -- Aplicar 15% de descuento
    ELSE
        v_precio_final := v_precio_original; -- Precio sin descuento
    END IF;

    -- Insertar la compra en la tabla COMPRAS_PRODUCTOS
    INSERT INTO COMPRAS_PRODUCTOS (
        ID_COMPRA, ID_USUARIO, FECHA_COMPRA, ID_PRODUCTO, ID_TIPO_PRODUCTO
    ) VALUES (
        SEQ_COMPRAS_PRODUCTOS.NEXTVAL, -- Asumimos que existe una secuencia para ID_COMPRA
        p_id_usuario, SYSDATE, p_id_producto, (SELECT ID_TIPO_PRODUCTO FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto)
    );

    -- Actualizar la configuración del asistente con la prenda comprada y seleccionada
    INSERT INTO CONFIGURACIONES_ROPA (
        ID, ID_ASISTENTE, ID_PRODUCTO, SELECCIONADO
    ) VALUES (
        SEQ_CONFIGURACIONES_ROPA.NEXTVAL, -- Asumimos que existe una secuencia para ID
        p_id_asistente, p_id_producto, 1
    );

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'El producto o la suscripción no se encontraron.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Ocurrió un error al efectuar la compra de la prenda: ' || SQLERRM);
END;


-- Implementar un servicio que acredite 50 gemas a los usuarios en el día de su cumpleaños. Los
-- usuarios que recibirán este beneficio son aquellos que cuenten con una antigüedad mínima de 6
-- meses y que además tengan una suscripción Replika Pro activa.
-- Nota: Este servicio será agendado para ser ejecutado diariamente


CREATE OR REPLACE PROCEDURE acreditar_gemas_cumpleanos IS
BEGIN
    -- Acreditar 50 gemas a los usuarios que cumplen años hoy, tienen más de 6 meses de antigüedad y una suscripción activa
    FOR usuario IN (
        SELECT u.id_usuario, b.id_billetera
        FROM USUARIOS u
        JOIN BILLETERA b ON u.id_usuario = b.id_usuario
        JOIN SUSCRIPCIONES s ON u.id_usuario = s.id_usuario
        WHERE 
            EXTRACT(MONTH FROM u.fecha_nacimiento) = EXTRACT(MONTH FROM SYSDATE)
            AND EXTRACT(DAY FROM u.fecha_nacimiento) = EXTRACT(DAY FROM SYSDATE)
            AND u.fecha_registro <= ADD_MONTHS(SYSDATE, -6)
            AND s.tipo = '12 MESES'
            AND s.fecha_vencimiento > SYSDATE
    ) LOOP
        -- Acreditar 50 gemas en la billetera del usuario
        UPDATE BILLETERA
        SET gemas = gemas + 50
        WHERE id_billetera = usuario.id_billetera;

        -- Opcional: Registrar el crédito en un log de beneficios
        INSERT INTO LOG_BENEFICIOS (
            ID_LOG, ID_USUARIO, TIPO_BENEFICIO, FECHA_BENEFICIO, CANTIDAD
        ) VALUES (
            SEQ_LOG_BENEFICIOS.NEXTVAL, -- Asumimos que existe una secuencia para ID_LOG
            usuario.id_usuario, 'Acreditación de gemas por cumpleaños', SYSDATE, 50
        );
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20012, 'Ocurrió un error al acreditar gemas a los usuarios: ' || SQLERRM);
END;


-- Crear un servicio que permita a un usuario seleccionar un idioma para aprender. Se debe considerar
-- que el usuario debe tener un asistente virtual de rol tutor para aprender idiomas, en caso de que no lo
-- tenga se debe devolver un mensaje de error descriptivo.

CREATE OR REPLACE PROCEDURE seleccionar_idioma (
    p_id_usuario IN NUMBER,
    p_id_idioma IN NUMBER
) IS
    v_id_asistente NUMBER;
    v_tiene_rol_tutor NUMBER;
BEGIN
    -- Verificar si el usuario tiene un asistente con el rol 'TUTOR'
    SELECT av.id_asistente INTO v_id_asistente
    FROM ASISTENTES_VIRTUALES av
    JOIN ASISTENTE_ROLES ar ON av.id_asistente = ar.id_asistente
    WHERE av.id_usuario = p_id_usuario
      AND ar.nombre_rol = 'TUTOR'
    FETCH FIRST 1 ROWS ONLY;

    -- Si se encuentra un asistente con rol 'TUTOR', registrar el idioma
    INSERT INTO ASISTENTE_TUTOR_IDIOMAS (
        id_asistente, id_idioma
    ) VALUES (
        v_id_asistente, p_id_idioma
    );

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20013, 'El usuario no tiene un asistente virtual con el rol "TUTOR". No se puede seleccionar un idioma.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20014, 'Ocurrió un error al seleccionar el idioma: ' || SQLERRM);
END;
