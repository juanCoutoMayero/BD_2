CREATE TABLE PAISES (
    ID_PAIS NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NOMBRE  VARCHAR (100) NOT NULL UNIQUE
);

CREATE TABLE USUARIOS (
    id_usuario NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    correo_electronico VARCHAR (100) NOT NULL UNIQUE,
    nombre VARCHAR (100) NOT NULL,
    contraseña VARCHAR (100) NOT NULL,
    ID_PAIS NUMBER NOT NULL,
    fecha_nacimiento date NOT NULL,
    fecha_registro DATE DEFAULT SYSDATE NOT NULL,
    rango_edad VARCHAR (20) NOT NULL check (rango_edad in ('18-24', '25-34', '35-44', '55-64', '65 o mas')),
    genero CHAR(1) NOT NULL CHECK (genero in ('M', 'F')),
    telefono VARCHAR (15) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL  CHECK (version IN ('PRO', 'GRATUITA')),
    FOREIGN KEY (ID_PAIS) REFERENCES PAISES(ID_PAIS)
);

CREATE TABLE BILLETERA (
    id_billetera NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    monedas NUMBER NOT NULL,
    gemas NUMBER NOT NULL,
    id_usuario NUMBER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);

CREATE TABLE ASISTENTES_VIRTUALES (
    id_asistente NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    nombre_asistente VARCHAR (100) NOT NULL,
    genero_asistente CHAR (2) CHECK(genero_asistente IN ('M', 'F', 'NB')),
    descripcion VARCHAR (500) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);


CREATE TABLE IDIOMAS (
    id_idioma NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre_idioma VARCHAR (50) NOT NULL UNIQUE
);

CREATE TABLE ASISTENTE_IDIOMAS (
    id_asistente NUMBER NOT NULL,
    id_idioma NUMBER NOT NULL,
    FOREIGN KEY (id_asistente) REFERENCES ASISTENTES_VIRTUALES(id_asistente),
    FOREIGN KEY (id_idioma) REFERENCES IDIOMAS (id_idioma),
    PRIMARY KEY (id_asistente, id_idioma)
);

CREATE TABLE ASISTENTE_ROLES (
    id_asistente NUMBER NOT NULL,
    nombre_rol VARCHAR(50) NOT NULL CHECK(nombre_rol IN ('AMIGO', 'TUTOR', 'COACH')),
    tipo_rol VARCHAR(50) NULL,
    PRIMARY KEY (id_asistente, nombre_rol),
    FOREIGN KEY (id_asistente) REFERENCES ASISTENTES_VIRTUALES(id_asistente),
    CHECK (
        (nombre_rol = 'TUTOR' AND tipo_rol IN ('APOYO EDUCATIVO', 'ENSEÑANZAS DE IDIOMAS', 'PREPARACIÓN DE EXÁMENES'))
        OR
        (nombre_rol = 'COACH' AND tipo_rol IN ('PLANIFICACIÓN', 'ORGANIZACIÓN DEL TIEMPO'))
        OR
        (nombre_rol = 'AMIGO' AND tipo_rol IS NULL)
    )
);


CREATE TABLE ASISTENTE_TUTOR_IDIOMAS (
    id_asistente NUMBER NOT NULL,
    id_idioma NUMBER NOT NULL,
    PRIMARY KEY (id_asistente, id_idioma),
    FOREIGN KEY (id_asistente) REFERENCES ASISTENTES_VIRTUALES (id_asistente),
    FOREIGN KEY (id_idioma) REFERENCES IDIOMAS (id_idioma)
);


CREATE TABLE PAQUETES(
    id_paquete NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    precio  NUMBER NOT NULL,
    cantidad NUMBER NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK(tipo IN ('GEMA', 'MONEDA')),
    descuento NUMBER NOT NULL CHECK(descuento >= 0 AND descuento<=100)
);

CREATE TABLE COMPRA_PAQUETES(
    ID_COMPRA NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_USUARIO NUMBER NOT NULL,
    ID_PAQUETE NUMBER NOT NULL,
    PRECIO  NUMBER NOT NULL,
    FECHA_COMPRA DATE DEFAULT SYSDATE NOT NULL,
    FOREIGN KEY (ID_PAQUETE) REFERENCES PAQUETES(ID_PAQUETE),
    FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS(ID_USUARIO)
);

CREATE TABLE INTEGRACIONES(
    id_integracion NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario),
    id_aplicacion VARCHAR(50) NOT NULL,
    fecha_confirmacion DATE NOT NULL
);
CREATE TABLE TIPOS_PRODUCTO(
    ID_TIPO_PRODUCTO NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    TIPO_PRODUCTO VARCHAR(50) CHECK(TIPO_PRODUCTO IN ('ROPA', 'INTERESES', 'APARIENCIAS', 'RASGOS_PERSONALIDAD'))
);

CREATE TABLE PRODUCTOS (
    ID_PRODUCTO NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NOMBRE VARCHAR(50) NOT NULL,
    PRECIO NUMBER NOT NULL,
    TIPO_MONEDA VARCHAR(50) NOT NULL CHECK (TIPO_MONEDA IN ('GEMA', 'MONEDA')),
    POR_DEFECTO NUMBER NOT NULL CHECK (POR_DEFECTO IN (0, 1)),
    ID_TIPO_PRODUCTO NUMBER NOT NULL,
    IMAGEN VARCHAR(50) NOT NULL,
    DESCRIPCION VARCHAR(50) NULL,
    ID_CATEGORIA NUMBER NULL,
    FOREIGN KEY (ID_TIPO_PRODUCTO) references TIPOS_PRODUCTO(ID_TIPO_PRODUCTO)
);


CREATE TABLE CATEGORIAS(
    ID_CATEGORIA NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_TIPO_PRODUCTO NUMBER NOT NULL,
    NOMBRE VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE CONFIGURACIONES_ROPA(
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_ASISTENTE NUMBER NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    SELECCIONADO NUMBER NOT NULL CHECK(SELECCIONADO IN (0,1)),
    FOREIGN KEY (ID_ASISTENTE) REFERENCES ASISTENTES_VIRTUALES(ID_ASISTENTE),
    FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO)
);

CREATE TABLE CONFIGURACIONES_APARIENCIAS(
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_ASISTENTE NUMBER NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    SELECCIONADO NUMBER NOT NULL CHECK(SELECCIONADO IN (0,1)),
    FOREIGN KEY (ID_ASISTENTE) REFERENCES ASISTENTES_VIRTUALES(ID_ASISTENTE),
    FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO)
);

CREATE TABLE CONFIGURACIONES_INTERESES(
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_ASISTENTE NUMBER NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    SELECCIONADO NUMBER NOT NULL CHECK(SELECCIONADO IN (0,1)),
    FOREIGN KEY (ID_ASISTENTE) REFERENCES ASISTENTES_VIRTUALES(ID_ASISTENTE),
    FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO)
);

CREATE TABLE CONFIGURACIONES_RASGOS_PERSONALIDAD(
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_ASISTENTE NUMBER NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    SELECCIONADO NUMBER NOT NULL CHECK(SELECCIONADO IN (0,1)),
    FOREIGN KEY (ID_ASISTENTE) REFERENCES ASISTENTES_VIRTUALES(ID_ASISTENTE),
    FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO)
);



CREATE TABLE COMPRAS_PRODUCTOS (
    ID_COMPRA NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_USUARIO NUMBER NOT NULL,
    FECHA_COMPRA DATE DEFAULT SYSDATE NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    ID_TIPO_PRODUCTO NUMBER NOT NULL,
    FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS(ID_USUARIO)
    );


CREATE TABLE VOCES(
    ID_VOZ NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_ASISTENTE NUMBER NOT NULL,
    TIPO VARCHAR(50) NOT NULL CHECK(TIPO IN ('FEMININA', 'MASCULINA')),
    TONO VARCHAR(50) NOT NULL CHECK(TONO IN ('ALEGRE', 'CALMO', 'SEGURO', 'ENERGÉTICO', 'OPTIMISTA')),
    POR_DEFECTO NUMBER NOT NULL CHECK(POR_DEFECTO IN (0,1)),
    FOREIGN KEY (ID_ASISTENTE) REFERENCES ASISTENTES_VIRTUALES(ID_ASISTENTE)
);


CREATE TABLE SUSCRIPCIONES(
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_USUARIO NUMBER NOT NULL,
    TIPO VARCHAR(50) NOT NULL CHECK(TIPO IN ('1 MES', '12 MESES', 'DE_POR_VIDA')),
    FECHA_COMPRA DATE NOT NULL,
    FECHA_VENCIMIENTO DATE,
    MEDIO_DE_PAGO VARCHAR(50) NOT NULL CHECK(MEDIO_DE_PAGO IN ('PAYPAL', 'TC')),
    FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS(ID_USUARIO)
);

CREATE TABLE LOG_BENEFICIOS (
    ID_LOG NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_USUARIO NUMBER NOT NULL,
    TIPO_BENEFICIO VARCHAR2 (50),
    FECHA_BENEFICIO DATE,
    CANTIDAD number NOT NULL
);
