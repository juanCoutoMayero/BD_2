-- Implementar un servicio que cree un nuevo usuario en el sistema. Esto implica inicializar al asistente
-- virtual con rol amigo y su respectiva configuración predeterminada (apariencia). Aquella información
-- que no se puede obtener de forma predeterminada se podrá enviar al servicio por parámetro.

CREATE OR REPLACE PROCEDURE sp_alta_usuario(
    -- DATOS DE USUARIO
    p_correo_electronico IN VARCHAR,
    p_nombre IN VARCHAR,
    p_contraseña IN VARCHAR,
    p_id_pais IN NUMBER,
    p_fecha_nacimiento IN DATE,
    p_genero IN CHAR,
    p_telefono IN VARCHAR,

    -- DATOS DE ASISTENTE
    p_nombre_asistente IN VARCHAR,
    p_genero_asistente IN CHAR,
    p_historia IN VARCHAR,
    p_id_idioma IN NUMBER
) AS
    v_nuevo_id_usuario NUMBER;
    v_nuevo_id_asistente NUMBER;
    v_fecha_registro DATE := SYSDATE;
    v_rango_edad VARCHAR2(20);
    v_id_billetera NUMBER;
    v_id_ropa_por_defecto NUMBER;
    v_id_apariencia_por_defecto NUMBER;
    v_contador_paises NUMBER;
    v_contador_idiomas NUMBER;
BEGIN
    -- Validar que el país exista
    SELECT COUNT(*)
    INTO v_contador_paises
    FROM PAISES
    WHERE ID_PAIS = p_id_pais;
    IF v_contador_paises = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El id_país no existe.');
    END IF;

    -- Calcular el rango de edad
    SELECT fx_obtener_rango_edad(p_fecha_nacimiento)
    INTO v_rango_edad
    FROM DUAL;

    -- Obtener la ropa por defecto (validar un solo registro)
    SELECT id_producto INTO v_id_ropa_por_defecto
    FROM productos p
    JOIN TIPOS_PRODUCTO t ON p.ID_TIPO_PRODUCTO = t.ID_TIPO_PRODUCTO
    WHERE t.TIPO_PRODUCTO LIKE '%ROPA%'
    AND ROWNUM = 1;

    -- Obtener la apariencia por defecto (validar un solo registro)
    SELECT id_producto INTO v_id_apariencia_por_defecto
    FROM productos p
    JOIN TIPOS_PRODUCTO t ON p.ID_TIPO_PRODUCTO = t.ID_TIPO_PRODUCTO
    WHERE t.TIPO_PRODUCTO LIKE '%APARIENCIA%'
    AND ROWNUM = 1;

    -- Insertar en USUARIOS
    INSERT INTO USUARIOS
    (CORREO_ELECTRONICO, NOMBRE, CONTRASEÑA, ID_PAIS, FECHA_NACIMIENTO,
    FECHA_REGISTRO, RANGO_EDAD, GENERO, TELEFONO, VERSION)
    VALUES (p_correo_electronico, p_nombre, p_contraseña, p_id_pais,
    p_fecha_nacimiento, v_fecha_registro, v_rango_edad, p_genero, p_telefono, 'GRATUITA')
    RETURNING id_usuario INTO v_nuevo_id_usuario;

    -- Insertar en BILLETERA
    INSERT INTO BILLETERA (MONEDAS, GEMAS, ID_USUARIO)
    VALUES (0, 0, v_nuevo_id_usuario);

    -- Insertar en ASISTENTES_VIRTUALES
    INSERT INTO ASISTENTES_VIRTUALES (ID_USUARIO, NOMBRE_ASISTENTE, GENERO_ASISTENTE, DESCRIPCION)
    VALUES (v_nuevo_id_usuario, p_nombre_asistente, p_genero_asistente, p_historia)
    RETURNING id_asistente INTO v_nuevo_id_asistente;

    -- Validar que el idioma exista
    SELECT COUNT(*)
    INTO v_contador_idiomas
    FROM IDIOMAS
    WHERE ID_IDIOMA = p_id_idioma;
    IF v_contador_idiomas = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El id_idioma no existe.');
    END IF;

    -- Insertar en ASISTENTE_IDIOMAS
    INSERT INTO ASISTENTE_IDIOMAS (ID_ASISTENTE, ID_IDIOMA)
    VALUES (v_nuevo_id_asistente, p_id_idioma);

    -- Insertar en CONFIGURACIONES_ROPA (Por defecto)
    INSERT INTO CONFIGURACIONES_ROPA
    (ID_ASISTENTE, ID_PRODUCTO, SELECCIONADO)
    VALUES (v_nuevo_id_asistente, v_id_ropa_por_defecto, 1);

    -- Insertar en CONFIGURACIONES_APARIENCIAS (Por defecto)
    INSERT INTO CONFIGURACIONES_APARIENCIAS
    (ID_ASISTENTE, ID_PRODUCTO, SELECCIONADO)
    VALUES (v_nuevo_id_asistente, v_id_apariencia_por_defecto, 1);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20008, 'Ocurrió un error al crear el usuario y su configuración: ' || SQLERRM);
END sp_alta_usuario;


-- Elaborar un servicio que permita efectuar la compra de una prenda de ropa para el asistente virtual de
-- un determinado usuario. Tener en cuenta que si el usuario posee una suscripción Replika Pro activa
-- se le debe aplicar un descuento del 15 %.

CREATE OR REPLACE PROCEDURE sp_comprar_ropa(
    p_id_usuario in number,
    p_id_producto in number,
    p_id_tipo_producto in number
) AS
    v_precio_original number;
    v_precio_final number;
    v_tipo_suscripcion varchar(50);
    v_id_asistente number;
    
BEGIN

    -- Verificar si el producto es una prenda de ropa
    SELECT PRECIO INTO v_precio_original
    FROM PRODUCTOS
    WHERE ID_PRODUCTO = p_id_producto AND ID_TIPO_PRODUCTO = (SELECT ID_TIPO_PRODUCTO FROM TIPOS_PRODUCTO WHERE TIPO_PRODUCTO = 'ROPA');

    IF v_precio_original IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'El producto especificado no es una prenda de ropa válida.');
    END IF;

    -- Obtener el precio del producto
    select precio
    into v_precio_original
    from productos p
    join tipos_producto t on p.id_tipo_producto = t.id_tipo_producto
    where p.id_producto = p_id_producto and t.tipo_producto like '%ROPA%';
    
    -- Verificar si el usuario tiene suscripcion PRO
    select version
    into v_tipo_suscripcion
    from usuarios
    where id_usuario = p_id_usuario;
    
    -- Obtener el id_asistente
    select id_asistente
    into v_id_asistente
    from asistentes_virtuales
    where id_usuario = p_id_usuario;
    
    if v_tipo_suscripcion like '%PRO%' then
        v_precio_final := v_precio_original*0.85;
    else
        v_precio_final := v_precio_original;
    end if;
    
    -- Insertar en COMPRAS_PRODUCTOS
    insert into COMPRAS_PRODUCTOS
    (ID_USUARIO, FECHA_COMPRA, ID_PRODUCTO, ID_TIPO_PRODUCTO)
    values (p_id_usuario, SYSDATE, p_id_producto, p_id_tipo_producto);
    
    -- Insertar en CONFIGURACIONES_ROPA
    insert into CONFIGURACIONES_ROPA
    (ID_ASISTENTE, ID_PRODUCTO, SELECCIONADO)
    values (v_id_asistente, p_id_producto, 0);

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'El producto  no se encontró.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Ocurrió un error al efectuar la compra de la prenda: ' || SQLERRM);
END sp_comprar_ropa;


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
        WHERE
            EXTRACT(MONTH FROM u.fecha_nacimiento) = EXTRACT(MONTH FROM SYSDATE)
            AND EXTRACT(DAY FROM u.fecha_nacimiento) = EXTRACT(DAY FROM SYSDATE)
            AND u.fecha_registro <= ADD_MONTHS(SYSDATE, -6)
            AND u.version like '%PRO%'
            AND NOT EXISTS (
                SELECT 1
                FROM LOG_BENEFICIOS lb
                WHERE lb.id_usuario = u.id_usuario
                  AND lb.tipo_beneficio = 'Acreditación de gemas por cumpleaños'
                  AND TRUNC(lb.fecha_beneficio) = TRUNC(SYSDATE)
            )
    ) LOOP
        BEGIN
            -- Acreditar 50 gemas en la billetera del usuario
            UPDATE BILLETERA
            SET gemas = gemas + 50
            WHERE id_billetera = usuario.id_billetera;

            -- Registrar el crédito en un log de beneficios
            INSERT INTO LOG_BENEFICIOS (
                ID_LOG, ID_USUARIO, TIPO_BENEFICIO, FECHA_BENEFICIO, CANTIDAD
            ) VALUES (
                SEQ_LOG_BENEFICIOS.NEXTVAL, -- Asumimos que existe una secuencia para ID_LOG
                usuario.id_usuario, 'Acreditación de gemas por cumpleaños', SYSDATE, 50
            );

            -- Confirmar transacción para este usuario
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE_APPLICATION_ERROR(-20012, 'Ocurrió un error al acreditar gemas a los usuarios: ' || SQLERRM);
        END;
    END LOOP;
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
