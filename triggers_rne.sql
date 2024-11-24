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
    
    -- Validar si el rol es 'TUTOR' o 'COACH' y la versión no es 'PRO'
    IF (:NEW.nombre_rol IN ('TUTOR', 'COACH') AND v_version != 'PRO') THEN
        RAISE_APPLICATION_ERROR(-20001, 'El usuario debe tener la versión "PRO" para asignar roles de tipo "TUTOR" o "COACH".');
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

-- Restricción en CONFIGURACIONES_APARIENCIAS. Un asistente virtual puede tener solo una APARIENCIA seleccionada por categoria .

CREATE OR REPLACE TRIGGER deseleccionar_apariencia_duplicada
BEFORE INSERT OR UPDATE ON CONFIGURACIONES_APARIENCIAS
FOR EACH ROW
BEGIN
    -- Si la nueva apariencia está siendo seleccionada, deseleccionar la apariencia actual en la misma categoría
    IF :NEW.SELECCIONADO = 1 THEN
        UPDATE CONFIGURACIONES_APARIENCIAS
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


-- Las categorias solo pueden ser de tipo ROPA o Apariencia

CREATE OR REPLACE TRIGGER validar_categorias_por_tipo_producto
BEFORE INSERT OR UPDATE ON CATEGORIAS
FOR EACH ROW
DECLARE
    v_tipo_producto VARCHAR2(50);
BEGIN
    -- Obtener el tipo de producto para validar su tipo
    SELECT TIPO_PRODUCTO INTO v_tipo_producto
    FROM TIPOS_PRODUCTO
    WHERE ID_TIPO_PRODUCTO = :NEW.ID_TIPO_PRODUCTO;

    -- Validar que el tipo de producto sea 'ROPA' o 'APARIENCIAS'
    IF v_tipo_producto NOT IN ('ROPA', 'APARIENCIAS') THEN
        RAISE_APPLICATION_ERROR(-20008, 'Las categorías solo pueden ser asociadas a tipos de producto "ROPA" o "APARIENCIAS".');
    END IF;
END;

-- Restricción en PRODUCTOS. Solamente un PRODUCTO del mismo tipo de producto  y misma categoria puede estar marcado como "por defecto".

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
          AND (:NEW.ID_PRODUCTO IS NULL OR ID_PRODUCTO <> :NEW.ID_PRODUCTO);  -- Evitar deseleccionar la misma fila en caso de UPDATE
    END IF;
END;
