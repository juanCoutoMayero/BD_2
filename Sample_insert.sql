-- Inserción de un documento de ejemplo para un usuario
db.usuarios.insertOne({
    "_id": "usuario_123",
    "nombre": "Juan Pérez",
    "email": "juan.perez@example.com",
    "fecha_registro": ISODate("2023-01-15T00:00:00Z"),
    "interacciones": [
        {
            "id_interaccion": "interaccion_001",
            "fecha_hora": ISODate("2024-11-10T14:30:00Z"),
            "tipo": "tutoría",
            "idioma": "Español",
            "respuestas_asistente": [
                {
                    "texto": "Esto es lo que necesitas saber sobre el tema...",
                    "tipo_respuesta": "explicación"
                }
            ]
        },
        {
            "id_interaccion": "interaccion_002",
            "fecha_hora": ISODate("2024-11-12T15:45:00Z"),
            "tipo": "conversación casual",
            "idioma": "Inglés",
            "respuestas_asistente": [
                {
                    "texto": "¡Claro! Hablemos de eso...",
                    "tipo_respuesta": "diálogo"
                }
            ]
        }
    ],
    "progreso_aprendizaje": {
        "sesiones_completadas": 10,
        "niveles_idioma": [
            {
                "idioma": "Inglés",
                "nivel": "Intermedio"
            },
            {
                "idioma": "Francés",
                "nivel": "Básico"
            }
        ],
        "logros_certificaciones": [
            {
                "nombre": "Certificado de Inglés B2",
                "idioma": "Inglés",
                "fecha_obtencion": ISODate("2024-10-10T00:00:00Z"),
                "nivel_dominio": "Intermedio"
            },
            {
                "nombre": "Certificado de Tutoría Avanzada",
                "idioma": "Español",
                "fecha_obtencion": ISODate("2024-05-05T00:00:00Z"),
                "nivel_dominio": "Avanzado"
            }
        ]
    }
});
