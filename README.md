# Front_AlphaECI

Frontend en Flutter de **AlphaECI**, la app de matching social de la Escuela Colombiana de Ingeniería. Una sola base de código para Android, iOS, Web, Windows, macOS y Linux.

La app permite descubrir estudiantes afines, hacer match, chatear, crear y unirse a *parches* (planes en el campus), publicar en el feed, ver eventos institucionales, consultar recursos de bienestar, ubicarse en el mapa del campus y coleccionar *monas* (medallas de gamificación).

---

## Arranque rápido

```bash
flutter pub get
flutter run -d chrome --dart-define=DEMO=true
```

`DEMO=true` levanta la app completa **sin necesidad de backends**: todos los repositorios usan implementaciones mock con datos de muestra y el login acepta cualquier correo/contraseña. Es la forma más rápida de ver la app funcionando.

Para conectar contra los servicios reales, ver [Configuración](#configuración).

## Stack

| Área | Elección |
|---|---|
| Framework | Flutter (Dart SDK `^3.12.2`), Material 3 |
| Estado + inyección de dependencias | `flutter_riverpod` |
| HTTP | `dio` (un cliente por servicio, con interceptor de auth) |
| Routing | `go_router` (redirect por estado de sesión) |
| Tokens JWT | `flutter_secure_storage` |
| Chat en tiempo real | `stomp_dart_client` (STOMP sobre WebSocket) |
| Mapa del campus | `flutter_map` + `latlong2` (OpenStreetMap, sin API key) |
| Subida de imágenes | `firebase_core` + `firebase_storage` |
| Tipografía | `google_fonts` (Montserrat titulares, Inter cuerpo) |

## Estructura

```text
lib/
├── main.dart          # bootstrap: Firebase + ProviderScope
├── app.dart           # MaterialApp.router + tema + banner DEMO
├── core/              # infraestructura compartida
│   ├── config/        # Env (URLs por --dart-define, flags DEMO/FIREBASE_TEST)
│   ├── network/       # Dio, AuthInterceptor, bus de expiración de sesión
│   ├── errors/        # Failure (sealed), Result<T>, mapper de DioException
│   ├── storage/       # TokenStorage (secure storage), MediaUploadService
│   ├── router/        # GoRouter + paths centralizados
│   ├── theme/         # colores, tipografía, design tokens, ThemeMode
│   ├── utils/         # breakpoints, validadores, decoder de JWT
│   └── widgets/       # AdaptiveScaffold, AppButton, AsyncValueView, ...
└── features/          # una carpeta por dominio, tres capas cada una
    ├── auth/ profile/ matching/ chat/ parches/ feed/ events/
    ├── notifications/ bienestar/ geo/ gamification/ stats/ home/
    └── ...            # cada feature: data/ · domain/ · presentation/
```

## Configuración

Todo se pasa con `--dart-define`. Sin flags, la app apunta al API Gateway en `http://localhost:8080`.

| Flag | Default | Para qué |
|---|---|---|
| `GATEWAY_URL` | `http://localhost:8080` | Única puerta de entrada REST. Cambia esta y todos los servicios la siguen. |
| `DEMO` | `false` | Repositorios mock, sin backends, login libre. Muestra una cinta "DEMO". |
| `FIREBASE_TEST` | `false` | Mocks para todo excepto Firebase Storage (para probar subida de fotos sin backends). Implica `DEMO`. |
| `AUTH_URL`, `PROFILE_URL`, `MATCHING_URL`, `CHAT_URL`, `NOTIFICATION_URL`, `EVENT_URL`, `BIENESTAR_URL`, `GEO_URL`, `GAMIFICATION_URL`, `STATS_URL`, `PARCHES_URL`, `CHAT_WS_URL` | `GATEWAY_URL` | Override por servicio, para apuntar a un despliegue puntual. |

Ejemplo apuntando a un gateway desplegado:

```bash
flutter run -d chrome --dart-define=GATEWAY_URL=https://gateway.alphaeci.example
```

Definición en [lib/core/config/env.dart](lib/core/config/env.dart).

## Comandos

```bash
flutter pub get      # instalar dependencias
flutter analyze      # linter — correr antes de cada commit
flutter test         # tests de widget
dart format lib/     # formatear
flutter clean        # limpiar caché de build
```

## Documentación

| Documento | Contenido |
|---|---|
| [docs/GUIA_DESARROLLADOR.md](docs/GUIA_DESARROLLADOR.md) | Setup desde cero, cómo correr, cómo agregar una funcionalidad, problemas frecuentes. **Empieza aquí si eres nuevo.** |
| [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) | Capas, flujo de datos, auth, errores, tema, responsive, decisiones técnicas. |
| [docs/FEATURES.md](docs/FEATURES.md) | Mapa feature por feature: pantallas, providers, endpoints consumidos, estado. |
| [docs/DESCRIPCION_MEDALLAS.md](docs/DESCRIPCION_MEDALLAS.md) | Descripción visual de las 35 monas (medallas de gamificación). |
| [docs/Navegacion_AlphaECI.drawio](docs/Navegacion_AlphaECI.drawio) | Diagrama de navegación entre pantallas. |
| [storage.rules](storage.rules) | Reglas de Firebase Storage. Ver la advertencia de seguridad ahí. |
