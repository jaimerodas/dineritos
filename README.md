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
Esto es una app de Rails 6, corriendo sobre Ruby 2.6.5. Usamos postgresql como
db. Si tienes Ruby y yarn instalados, puedes simplemente correr

```bash
bundle && yarn && rails db:setup
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

[1]: https://fixer.io
[2]: https://postmarkapp.com
