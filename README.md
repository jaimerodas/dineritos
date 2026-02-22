[![codecov](https://codecov.io/gh/jaimerodas/dineritos/graph/badge.svg?token=NIID1NX94K)](https://codecov.io/gh/jaimerodas/dineritos)

# Dineritos
Como me he puesto a investigar qué tal funcionan distintos instrumentos de
inversión, tengo mi dinero dividido entre varias cuentas. Originalmente llevaba
el registro de los saldos en un excel, pero eso tiene muchos contras. Hice
*Dineritos* para poder llevar este registro en los internets y poder ver el
estatus de mi lana en cualquier lado.

La aplicación es muy sencilla. Puedes crear cuentas (en MXN ó USD) e ir
reportando los saldos de las mismas a través del tiempo. Por default puedes ver
cómo ha cambiado tu saldo vs la última fecha que se tiene info, pero también hay
vistas para ver la evolución a través del tiempo del total de saldos y de cada
cuenta en particular.

## Instalación
Esto es una app de Rails 8.1, corriendo sobre Ruby 3.4.7. Usamos PostgreSQL como
db. Si tienes Ruby ya instalado, puedes simplemente correr

```bash
bundle && rails db:setup
```

## Configuración
Vas a necesitar varias variables de configuración pa que jale esto,
específicamente:
- `fixer`: el API key de [fixer.io][1]
- `auth_secret`: un secreto que genero para validar sesiones
- `postmark`: el API key de [Postmark][2] para poder enviar correos

Yo guardo estas en el archivo de `credentials.yml.enc`, y si quieres correr esto
tú, vas a tener que sobreescribir ese archivo con tus propias variables y
encriptarlo con tu propia master key.

## Conversión de divisas
Cuando una cuenta la marcas en dólares, la app busca en [fixer.io][1] el tipo de
cambio a pesos para ese día y convierte la moneda. Tú nunca tienes que meter
tipos de cambio.

## Deployment

La app se deploya automáticamente a un droplet de DigitalOcean usando
[Kamal 2](https://kamal-deploy.org). Al hacer push a `main` y pasar el CI, GitHub
Actions construye la imagen Docker, la sube a ghcr.io, y ejecuta `kamal deploy`.

### Aliases de Kamal
```bash
kamal console     # Rails console en producción
kamal logs        # Logs en tiempo real
kamal shell       # Bash en el container
kamal db-console  # psql a la base de producción
kamal db-dump     # Crear dump en /tmp/latest.dump en el server
kamal db-bash     # Bash en el container de PostgreSQL
```

### Bajar la base de producción
```bash
bin/update_db  # Dump + descarga + restore a dineritos_development
```

### Tareas programadas
Las tareas cron se configuran en `.kamal/hooks/post-deploy`, que actualiza el crontab
del servidor después de cada deploy:
- **Diario a las 5am CST**: actualiza saldos de todas las cuentas
- **Mensual**: limpia sesiones expiradas

### Deploy manual
```bash
kamal deploy  # Deploy manual (requiere secrets en env vars)
kamal setup   # Primer deploy (instala Docker, crea accessory de PG, etc.)
```

[1]: https://fixer.io
[2]: https://postmarkapp.com
