--TRIGGERS PARA LAS RNE

--Un usuario puede tener un asistente virtual de con el tipo rol 'Tutor' o 'Coach' solo si tiene version 'Pro'

CREATE OR REPLACE TRIGGER validar_version_pro
BEFORE INSERT OR UPDATE ON ASISTENTE_ROLES
FOR EACH ROW
DECLARE
    v_version VARCHAR2(50);
BEGIN
    -- Obtener la versión del usuario asociado al asistente virtual
    SELECT version INTO v_version
    FROM USUARIOS u
    JOIN ASISTENTES_VIRTUALES av ON u.id_usuario = av.id_usuario
    WHERE av.id_asistente = :NEW.id_asistente;
    
    -- Validar si el rol es 'Tutor' o 'Coach' y la versión no es 'Pro'
    IF (:NEW.nombre_rol IN ('TUTOR', 'COACH') AND v_version != 'Pro') THEN
        RAISE_APPLICATION_ERROR(-20001, 'El usuario debe tener la versión "Pro" para asignar roles de tipo "Tutor" o "Coach".');
    END IF;
END;

-- Restricción en CONFIGURACIONES_ROPA. Un asistente virtual puede tener solo una prenda por categoria seleccionada.

CREATE OR REPLACE TRIGGER deseleccionar_prenda_duplicada
BEFORE INSERT OR UPDATE ON CONFIGURACIONES_ROPA
FOR EACH ROW
BEGIN
    -- Si la nueva prenda está siendo seleccionada, deseleccionar la prenda actual en la misma categoría
    IF :NEW.SELECCIONADO = 1 THEN
        UPDATE CONFIGURACIONES_ROPA
        SET SELECCIONADO = 0
        WHERE ID_ASISTENTE = :NEW.ID_ASISTENTE
          AND ID_CATEGORIA = :NEW.ID_CATEGORIA
          AND SELECCIONADO = 1
          AND (:NEW.ID IS NULL OR ID <> :NEW.ID);  -- Evitar deseleccionar la misma fila en caso de UPDATE
    END IF;
END;

-- Todo producto de tipo apariencias o ropa debe tener una categoría asociada. 

CREATE OR REPLACE TRIGGER validar_categoria_productos
BEFORE INSERT OR UPDATE ON PRODUCTOS
FOR EACH ROW
DECLARE
    v_tipo_producto VARCHAR2(50);
BEGIN
    -- Obtener el tipo de producto para la validación
    SELECT TIPO_PRODUCTO INTO v_tipo_producto
    FROM TIPOS_PRODUCTO
    WHERE ID_TIPO_PRODUCTO = :NEW.ID_TIPO_PRODUCTO;

    -- Validar que si el tipo es 'APARIENCIAS' o 'ROPA', tenga una categoría asociada
    IF v_tipo_producto IN ('APARIENCIAS', 'ROPA') AND :NEW.ID_CATEGORIA IS NULL THEN
        RAISE_APPLICATION_ERROR(-20007, 'El producto debe tener una categoría asociada si es de tipo "APARIENCIAS" o "ROPA".');
    END IF;
END;


-- Restricción en PRODUCTOS. Solamente un PRODUCTO del mismo tipo de producto puede estar marcado como "por defecto".

CREATE OR REPLACE TRIGGER desmarcar_producto_por_defecto
BEFORE INSERT OR UPDATE ON PRODUCTOS
FOR EACH ROW
BEGIN
    -- Si el nuevo producto está marcado como por defecto, desmarcar el producto por defecto actual en la misma categoría y tipo de producto
    IF :NEW.POR_DEFECTO = 1 THEN
        UPDATE PRODUCTOS
        SET POR_DEFECTO = 0
        WHERE ID_TIPO_PRODUCTO = :NEW.ID_TIPO_PRODUCTO
          AND ID_CATEGORIA = :NEW.ID_CATEGORIA
          AND POR_DEFECTO = 1
          AND (:NEW.ID IS NULL OR ID <> :NEW.ID);  -- Evitar deseleccionar la misma fila en caso de UPDATE
    END IF;
END;
