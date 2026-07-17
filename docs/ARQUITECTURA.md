# Arquitectura Frontend — AlphaECI (Flutter)

Estado: **implementada**. Este documento describe cómo está construido el front hoy, no una propuesta.

Los endpoints listados fueron extraídos de los controladores reales de los repositorios backend y de las llamadas que hace el front. Nada está inventado.

---

## 1. Panorama

AlphaECI es un frontend Flutter único (Android, iOS, Web, Windows, macOS, Linux) contra una arquitectura de microservicios detrás de un **API Gateway** (AlphaGateway).

```
Flutter (este repo)
        │  REST (Dio) + WebSocket STOMP
        ▼
   API Gateway  ──►  identity · profile · matching · chat · notification
                     event · bienestar · geo · gamification · stats · parches
        
   Firebase Storage  ◄── subida de imágenes de posts (única pieza fuera del backend propio)
```

Todo el REST sale por una sola URL base (`GATEWAY_URL`, default `http://localhost:8080`). Cada servicio conserva un override individual (`AUTH_URL`, `CHAT_URL`, …) por si hay que apuntar directo a un despliegue puntual. Ver [lib/core/config/env.dart](../lib/core/config/env.dart).

## 2. Capas

Feature-first: una carpeta por dominio, tres capas dentro de cada una, más un núcleo compartido en `core/`.

```
presentation ──► domain ◄── data
```

| Capa | Contiene | No debe hacer |
|---|---|---|
| `presentation/` | Pantallas, widgets, providers de Riverpod | Llamar HTTP directamente |
| `domain/` | Entidades e interfaces de repository | Importar Dio o tocar JSON |
| `data/` | Modelos JSON, servicios API, implementaciones de repository (real y mock) | Importar widgets |

Reglas duras:

- `presentation` solo conoce `domain` (entidades + interfaces), a través de providers.
- `data` implementa las interfaces de `domain` y es la única capa que toca Dio/STOMP.
- Nada en `features/x` importa de `features/y`… **con una excepción deliberada**: `feed/` compone datos de `parches/` y `profile/`, y `home/` monta las pantallas de los demás features como tabs. Fuera de esos dos casos, lo compartido vive en `core/`.
- No hay carpeta `usecases/`: la lógica de orquestación vive en los providers, que es donde se necesita. Se agregará solo si un provider se vuelve inmanejable o si dos features necesitan la misma lógica.

Flujo completo de una petición:

```
Screen → Provider → Repository (interfaz) → RepositoryImpl → ApiService → Dio → Gateway → servicio
                                                    │
                                            Result<T> de vuelta (Success | Error(Failure))
```

La UI **nunca** ve una excepción cruda: los repositories capturan `DioException` y devuelven `Result<T>`.

## 3. El núcleo (`lib/core/`)

### `config/env.dart`

Clase `Env` con todo lo configurable por `--dart-define`: `gatewayUrl`, una URL por servicio, y dos flags:

- **`DEMO`** — la app entera funciona sin backends. Cada `xRepositoryProvider` devuelve un `MockXRepository` con datos de muestra en lugar de la implementación real. El login acepta cualquier credencial (los validadores hacen short-circuit) y `app.dart` pinta una cinta "DEMO".
- **`FIREBASE_TEST`** — flag temporal: mocks para todo, pero Firebase Storage real, para probar la subida de fotos sin levantar los backends. Implica `DEMO`. Está marcado `TODO(firebase-test)` y debe eliminarse cuando el backend esté desplegado.

El patrón de switch mock/real es siempre el mismo, una línea al principio del provider del repository:

```dart
final parcheRepositoryProvider = Provider<ParcheRepository>((ref) {
  if (Env.demoMode) return MockParcheRepository();
  return ParcheRepositoryImpl(...);
});
```

### `network/`

- **`api_client.dart`** — `apiClientProvider` es un `Provider.family<Dio, String>` indexado por `baseUrl`: un Dio por servicio, con timeouts (10s conexión / 20s recepción) y `LogInterceptor` solo en debug. Uso: `ref.watch(apiClientProvider(Env.authUrl))`.
- **`auth_interceptor.dart`** — un `QueuedInterceptor` que:
  1. agrega `Authorization: Bearer <accessToken>` a cada petición;
  2. agrega `X-User-Id`, decodificado del propio JWT (`JwtDecoder.userId`). Marcado `TODO(gateway)`: cuando el gateway inyecte el header, esto sale;
  3. ante un `401` (que no venga de `/api/v1/auth/*`), intenta `POST /api/v1/auth/refresh` **una vez**, reintenta la petición original con el token nuevo, y si el refresh falla limpia los tokens y notifica al `SessionExpiryBus`.

  Es `QueuedInterceptor` y no `Interceptor` a propósito: serializa los errores concurrentes, de modo que N peticiones que reciben 401 a la vez no disparan N refresh simultáneos. El refresh usa un Dio "desnudo" aparte, sin este interceptor, para no recursar.
- **`session_expiry_bus.dart`** — un `ChangeNotifier` minúsculo. El interceptor no puede tocar Riverpod, así que emite por el bus; `AuthController` lo escucha y hace logout local. De ahí, el `refreshListenable` del router redirige a `/login`.

### `errors/`

- `Failure` es una `sealed class`: `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `NotFoundFailure`, `ServerFailure(message, statusCode)`, `UnknownFailure`.
- `Result<T>` es sealed con dos ramas, `Success<T>(data)` y `Error<T>(failure)`, y un `when(success:, error:)` exhaustivo.
- `failure_mapper.dart` traduce `DioException` → `Failure` extrayendo el mensaje del body.

### `router/`

`routerProvider` construye el `GoRouter`. El `redirect` observa `authControllerProvider` mediante un `refreshListenable`, con tres estados:

| Estado de sesión | Comportamiento |
|---|---|
| `unknown` (restaurando desde secure storage) | Se queda en `/splash` |
| `unauthenticated` | Solo `/login`, `/register`, `/otp`, `/forgot-password`; cualquier otra ruta redirige a `/login` |
| `authenticated` | Splash y rutas públicas redirigen a `/home` |

Todos los paths están centralizados en `routes.dart` (`Routes.home`, `Routes.parcheDetailPath(id)`, …). **Nunca** se hardcodea una ruta en una pantalla.

Las rutas de detalle (`/parches/:id`, `/users/:id`, `/chats/:roomId`) reciben la entidad por `state.extra` en vez de recargarla por id. Consecuencia conocida: abrir esas URLs en frío (deep link, refresh del navegador) no tiene el objeto y cae a una pantalla de fallback. Está manejado, no roto, pero es la razón por la que el deep-linking real todavía no funciona.

Todas las páginas comparten una transición fade + slide sutil de 280 ms.

### `theme/`

Material 3 con la paleta oficial AlphaECI. Ambos `ColorScheme` se definen explícitamente (no `fromSeed`: la marca fija cada rol).

| Rol | Light | Dark | Uso |
|---|---|---|---|
| Primario | `#1A3F6D` | `#1E4A7D` | Botones principales, acciones importantes |
| Primario claro | `#3E6FA5` | `#39639A` | Hover, enlaces, elementos interactivos |
| Acento | `#6FA8DC` | `#5D95D1` | Destacados sutiles, notificaciones, badges |
| Secundario (gris) | `#A6ADB6` | `#7B828C` | Textos secundarios, íconos, bordes |
| Fondo | `#F6F7F9` | `#0E1117` | Fondo de pantallas |
| Superficie | `#FFFFFF` | `#161A22` | Tarjetas, modales |
| Texto principal | `#0F172A` | `#F1F5F9` | Alta legibilidad |

Además de `app_colors.dart` y `app_typography.dart` (Montserrat titulares + Inter cuerpo, vía `google_fonts`), hay un `design_tokens.dart` con las constantes de diseño: `AppRadii`, `AppSpacing`, `AppDurations`, `AppCurves`, `AppGradients`, `AppGlass` (efecto glassmorphism), `AppCategoryStyles` (color por categoría de parche) y `AppShadows`.

`themeModeProvider` expone el `ThemeMode` (claro/oscuro/sistema). Ningún widget usa colores hard-coded: todo sale de `Theme.of(context)` o de los tokens.

### `utils/` y `widgets/`

- `breakpoints.dart` — `mobile < 600`, `tablet < 1024`, `desktop ≥ 1024`. Las decisiones de layout se toman con `LayoutBuilder` sobre `constraints.maxWidth`, nunca con orientación ni tipo de dispositivo.
- `jwt_decoder.dart` — decodifica el payload del JWT para sacar el `userId` (sin verificar firma: eso es del backend).
- `validators.dart` — validación de formularios; hace short-circuit en modo demo.
- `widgets/` — la librería compartida: `AdaptiveScaffold` (`NavigationBar` inferior en móvil ↔ `NavigationRail` lateral en pantallas anchas), `AppButton`, `AppTextField`, `AppSheet`, `AsyncValueView` (loading/error/data uniforme), `ErrorView`, `EmptyState`, `GlassCard`, `GradientScaffold`, `LoadingSkeleton`, `ImageViewer`, `Charts`, `Mascot`, `SplashScreen`, animaciones.

### `storage/`

- `token_storage.dart` — `flutter_secure_storage` para el par access/refresh.
- `media_upload_service.dart` — sube imágenes de posts a Firebase Storage bajo `posts/{parcheId}/{userId}/{timestamp}.{ext}`, con ids saneados. Valida ≤ 5 MB y JPG/PNG/WEBP antes de subir.

  > **Advertencia de seguridad, sin resolver.** La app no usa Firebase Auth (el login es propio, email/OTP contra el backend), así que las reglas de Storage no pueden exigir `request.auth`. Hoy solo acotan prefijo, tipo y tamaño: cualquier cliente con la API key pública puede escribir en `/posts`. Antes de producción hay que elegir una de las cuatro salidas documentadas en el encabezado de `media_upload_service.dart` (custom tokens de Firebase Auth emitidos por el backend, signed upload URLs, subida vía backend, o validación backend de la `photoUrl`).

## 4. Autenticación, de punta a punta

1. **Registro** — `POST /init-verification` (dispara el OTP al correo) → pantalla OTP → `POST /verify-otp` (devuelve tokens) → `POST /complete-registration` (datos del perfil).
2. **Login** — `POST /login` con `{email, password}` → `{accessToken, refreshToken, tokenType}` → guardados en secure storage.
3. **Cada petición** — `AuthInterceptor` agrega `Authorization` y `X-User-Id`.
4. **Expiración** — 401 → refresh automático → reintento. Si el refresh falla: tokens borrados, `SessionExpiryBus` notifica, `AuthController` pasa a `unauthenticated`, el router redirige a `/login`.
5. **Arranque en frío** — `AuthController.build()` deja el estado en `unknown` y lanza `restoreSession()`; el router muestra el splash hasta que se resuelve.

## 5. Endpoints por servicio

Lo que el front consume hoy va marcado con ✅.

### identity-service — base `/api/v1/auth`

| Método | Ruta | |
|---|---|---|
| POST | `/init-verification` | ✅ |
| POST | `/verify-otp` | ✅ |
| POST | `/resend-otp` | ✅ |
| POST | `/complete-registration` | ✅ |
| POST | `/login` | ✅ |
| POST | `/refresh` | ✅ (interceptor) |
| POST | `/logout` | ✅ |
| POST | `/forgot-password` | ✅ |
| POST | `/reset-password` | ✅ |
| POST | `/change-password` | ✅ |

### profile-service — base `/api/v1/users`

Consumidos: `GET /:userId` ✅, `PATCH /:userId/student` ✅, `GET /tags` ✅, `POST /:userId/tags` ✅, `DELETE /:userId/tags/:tagId` ✅, `POST /batch` ✅ (resolución de autores del feed en una sola llamada).

Disponibles y sin usar: creación de usuarios (`POST /student|admin|organizer`), listados por rol, amigos (`GET|POST /:userId/friends`, `DELETE /:userId/friends/:friendId`), gamificación (`PATCH /:userId/xp|level|active-status`), media (`POST|GET /:userId/profile-image`), geolocalización (`PATCH /:userId/geolocation`), horarios (`POST|DELETE /:userId/schedules`).

`/api/v1/internal/*` es comunicación entre servicios: **no usar desde el front**.

### matching-service — base `/api/v1/matches`

Consumidos: `GET /recommendations/{userId}/scores` ✅, `POST /` ✅ (crear match), `GET /user/{userId}/received` ✅, `GET /user/{userId}/sent` ✅, `PATCH /{id}/status` ✅.

Sin usar: `GET /{id}`, `GET /user/{userId}`, `DELETE /{id}`, `GET /nearby`, `POST /recommendations/{userId}/filtered`, y todo `/api/v1/categories` (CRUD de categorías y tags).

### chat-service — base `/api/chat` + WebSocket

REST: `GET /connections` ✅, `GET /{chatRoomId}/messages` ✅ (paginado). Sin usar: `POST /messages/report`, `POST /connections/request`, `POST /connections/respond`.

WebSocket (STOMP sobre SockJS):

| | |
|---|---|
| Endpoint | `/ws-chat` |
| Enviar | `/app/chat/{chatRoomId}/send` |
| Suscribirse | `/topic/parche/{chatRoomId}/messages` |

### notification-service — base `/api/notifications`

Consumidos: `GET /` ✅ (paginado), `GET /unread/count` ✅ (badge de la campana), `PATCH /{id}/read` ✅, `PATCH /read-all` ✅. Sin usar: `POST /send` (interno), `POST /reminders`, `GET|PUT /preferences`.

### EventService — base `/api/events`

Consumidos: `GET /` ✅ (con filtro de categoría), `POST /{id}/rsvp` ✅ (confirmar), `PUT /{id}/rsvp` ✅ (cancelar), `GET /agenda` ✅.

### BienestarService — base `/api/bienestar`

Consumidos: `GET /resources` ✅ (con filtros), `GET /events` ✅, `GET /contacts` ✅. Sin usar: `GET|POST /contact`.

### GeoService — base `/api/zone`

Consumidos: `POST /` ✅ (guardar zona), `GET /me` ✅, `GET /catalog` ✅.

### GamificationService — base `/api/v1/gamification`

Consumido: `GET /users/{userId}/monas` ✅. Sin usar: `POST /activity`, `GET /catalog`, `GET /catalog/{monaCode}`, `GET /users/{userId}/progress*`.

### Estadisticas_Eci — base `/api/v1/metrics`

Consumido: `GET /user/{userId}` ✅ (estadísticas personales agregadas — es un BFF). Sin usar: `GET /integration` (métricas institucionales, rol admin).

### Parches-Service

Consumidos: `GET /api/parches` ✅ (búsqueda con filtros), `POST /api/parches` ✅, `POST /api/parches/{id}/join` ✅, `GET|POST /api/parches/{id}/posts` ✅, `GET /api/parches/{id}/members` ✅, comentarios y reacciones (`POST /api/posts/{postId}/comments`, `POST /api/posts/{postId}/reactions`, `POST /api/comments/{commentId}/reactions`). Sin usar: invitaciones (`POST /api/invitations`, `POST /api/invitations/{id}/accept`).

## 6. Deuda técnica conocida

| Marcador | Dónde | Qué falta |
|---|---|---|
| `TODO(gateway)` | `auth_interceptor.dart` | Quitar el header `X-User-Id` cuando el gateway lo inyecte |
| `TODO(firebase-test)` | `env.dart`, `main.dart`, `post_composer_sheet.dart` | Eliminar el flag `FIREBASE_TEST` cuando el backend esté desplegado |
| `TODO(seguridad-producción)` | `media_upload_service.dart` | Cerrar la escritura a Firebase Storage (hoy abierta) |
| `TODO(demo)` | `data/repositories/mock_*.dart` | Eliminar los mocks en producción |
| `TODO(backend)` | `feed_provider.dart` | El `GET` de posts no expone contadores de reacciones ni comentarios; los likes son estado local optimista. El `Parche` no expone hora de fin; la ventana para publicar se aproxima al día completo. |

También: el deep-linking a rutas de detalle (§3), y la cobertura de tests, que hoy es mínima (dos archivos: un smoke de notificaciones y un test de widget de `AppButton`).
