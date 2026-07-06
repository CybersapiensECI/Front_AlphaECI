# Arquitectura Frontend — AlphaECI (Flutter)

> Propuesta de arquitectura. **Aún no implementada** — este documento es el plan.
> Todos los endpoints listados fueron extraídos de los controladores reales de los repositorios backend. Nada está inventado.

---

## 1. Qué se detectó en cada backend

### Modelo de autenticación (transversal)

- `identity-service` emite JWT (`accessToken`, `refreshToken`, `tokenType`) vía `POST /api/v1/auth/login`.
- Los demás servicios esperan el header **`X-User-Id`** (12 usos detectados) y/o **`Authorization: Bearer <token>`** (3 usos). `matching-service` tiene un `KongAuthFilter`, lo que sugiere un **API Gateway (Kong)** que valida el JWT e inyecta `X-User-Id`.
- **TODO:** no existe repositorio del gateway en la carpeta. Confirmar URL base del gateway y si el front debe enviar `X-User-Id` directamente en desarrollo local.

### identity-service (Spring Boot + Redis + RabbitMQ, puerto local 8080)

Base: `/api/v1/auth`

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/init-verification` | Inicia verificación de email (OTP) |
| POST | `/complete-registration` | Completa registro |
| POST | `/verify-otp` | Valida OTP → devuelve tokens |
| POST | `/resend-otp` | Reenvía OTP |
| POST | `/login` | `{email, password}` → `{accessToken, refreshToken, tokenType}` |
| POST | `/refresh` | Renueva token con refreshToken |
| POST | `/logout` | Invalida refreshToken |
| POST | `/forgot-password` | Solicita reset |
| POST | `/reset-password` | Restablece contraseña |
| POST | `/change-password` | Cambia contraseña |

Swagger: `http://localhost:8080/swagger-ui.html`.

### profile-service (NestJS, puerto 8080, Swagger en `/api`)

Base: `/api/v1/users`

- Creación: `POST /student`, `POST /admin`, `POST /organizer`
- Consulta: `GET /` (lista), `GET /:userId`, `GET /student-profiles`, `GET /organizer-profiles`, `GET /admin-profiles`, `GET /tags`, `POST /batch`
- Actualización: `PATCH /:userId/student|admin|organizer`
- Eliminación: `DELETE /:userId`
- Amigos: `GET|POST /:userId/friends`, `DELETE /:userId/friends/:friendId`
- Gamificación: `PATCH /:userId/xp`, `PATCH /:userId/level`, `PATCH /:userId/active-status`
- Media: `POST|GET /:userId/profile-image`, `PATCH /:userId/geolocation`
- Horarios: `POST|DELETE /:userId/schedules`
- Tags: `GET /:userId/tags`, `GET /:userId/tags/names`, `POST /:userId/tags`, `DELETE /:userId/tags/:tagId`

También expone `/api/v1/internal/*` (solo comunicación entre servicios, **no usar desde el front**) y `GET /api/v1/health`.

### matching-service (Spring Boot, hexagonal, KongAuthFilter)

Base 1: `/api/v1/categories` — CRUD de categorías (`POST /`, `GET /{id}`, `GET /all`, `PATCH /{id}`, `DELETE /{id}`), CRUD de tags (`POST /tags`, `GET /tags/{id}`, `GET /tags/all`, `PATCH /tags/{id}`, `DELETE /tags/{id}`), `GET /{categoryId}/tags`, `GET /categories-with-tags`, `POST /with-tags`.

Base 2: `/api/v1/matches`

| Método | Ruta |
|---|---|
| POST | `/` (crear match) |
| GET | `/{id}` |
| GET | `/user/{userId}` · `/user/{userId}/sent` · `/user/{userId}/received` |
| PATCH | `/{id}/status` |
| DELETE | `/{id}` |
| GET | `/recommendations/{userId}` · `/nearby` · `/scores` |
| POST | `/recommendations/{userId}/filtered` |

### chat-service (Spring Boot + WebSocket STOMP)

REST base `/api/chat`:
- `GET /{chatRoomId}/messages` (paginado)
- `POST /messages/report`
- `POST /connections/request`, `POST /connections/respond`, `GET /connections`

WebSocket:
- Endpoint: `/ws-chat` (SockJS/STOMP)
- Prefijo de aplicación: `/app` → enviar a `/app/chat/{chatRoomId}/send`
- Suscripción: broker simple en `/topic`

### notification-service (Spring Boot, header `X-User-Id`)

Base `/api/notifications`:
- `GET /` (paginado), `GET /unread/count`
- `PATCH /{id}/read`, `PATCH /read-all`
- `POST /send` (interno), `POST /reminders`
- `GET|PUT /preferences`

### EventService (Spring Boot)

Base `/events`:
- `GET /` (con filtros), `GET /{id}`, `POST /`
- `POST /{id}/rsvp` (confirmar), `PUT /{id}/rsvp` (cancelar)
- `GET /agenda`

### BienestarService (Spring Boot)

Base `/bienestar`:
- `GET /resources` (con filtros), `GET /events`
- `GET|POST /contact`, `GET /contacts`

### GeoService (Spring Boot)

Base `/api/zone`:
- `POST /` (guardar zona), `GET /me`, `GET /catalog`

### GamificationService (Spring Boot + RabbitMQ, hexagonal)

Base `/api/v1/gamification`:
- `POST /activity` (registrar actividad)
- `GET /users/{userId}/monas`
- `GET /catalog`, `GET /catalog/{monaCode}`
- `GET /users/{userId}/progress`, `/progress/{monaCode}`, `/progress/in-progress`

### Estadisticas_Eci (Spring Boot, BFF, puerto 8082, JWT propio)

Base `/api/v1/metrics`:
- `GET /integration` (métricas institucionales, rol admin)
- `GET /user/{userId}` (estadísticas personales agregadas — BFF)

### Parches-Service (Spring Boot, hexagonal, Aggregate Root + State pattern)

- `/api/parches`: `POST /`, `GET /` (búsqueda con filtros), `POST /{parcheId}/join`, `POST|GET /{parcheId}/posts`, `GET /{parcheId}/members`
- `/api/invitations`: `POST /`, `POST /{invitationId}/accept`
- `/api`: `GET /posts`, `POST /posts/{postId}/comments`, `POST /posts/{postId}/reactions`, `POST /comments/{commentId}/reactions`

### Front_AlphaECI (estado actual)

Scaffold recién creado con `flutter create`: solo existe `lib/main.dart` (counter demo), sin dependencias adicionales. **Punto de partida limpio.**

---

## 2. Estructura de carpetas propuesta

Feature-first con tres capas por feature (presentación / dominio / datos) + núcleo compartido en `core/`.

```text
lib/
├── main.dart                        # bootstrap: env, ProviderScope, runApp
├── app.dart                         # MaterialApp.router + theme
│
├── core/
│   ├── config/
│   │   ├── env.dart                 # URLs base por servicio (dart-define)
│   │   └── constants.dart
│   ├── network/
│   │   ├── api_client.dart          # Dio configurado por servicio
│   │   ├── auth_interceptor.dart    # agrega Bearer + X-User-Id, refresh en 401
│   │   └── ws_client.dart           # STOMP para chat
│   ├── errors/
│   │   ├── failures.dart            # sealed class Failure (Network, Auth, Validation, Server...)
│   │   ├── exceptions.dart
│   │   └── result.dart              # Result<T> = Success | Error(Failure)
│   ├── storage/
│   │   └── token_storage.dart       # flutter_secure_storage
│   ├── router/
│   │   ├── app_router.dart          # go_router + redirect por auth
│   │   └── routes.dart              # nombres/paths centralizados
│   ├── theme/
│   │   ├── app_theme.dart           # Material 3, light/dark, ColorScheme.fromSeed
│   │   ├── app_colors.dart
│   │   └── app_typography.dart
│   ├── utils/
│   │   ├── breakpoints.dart         # mobile <600, tablet <1024, desktop
│   │   └── validators.dart
│   └── widgets/                     # componentes reutilizables globales
│       ├── adaptive_scaffold.dart   # NavigationBar ↔ NavigationRail según ancho
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── async_value_view.dart    # loading / error / data uniforme
│       ├── error_view.dart
│       └── empty_state.dart
│
└── features/
    ├── auth/                        # identity-service
    │   ├── data/
    │   │   ├── models/              # login_request.dart, login_response.dart, ... (espejo de DTOs)
    │   │   ├── services/            # auth_api_service.dart (llamadas HTTP crudas)
    │   │   └── repositories/        # auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/            # user_session.dart
    │   │   ├── repositories/        # auth_repository.dart (interfaz abstracta)
    │   │   └── usecases/            # login.dart, refresh_session.dart (solo si hay lógica real)
    │   └── presentation/
    │       ├── providers/           # auth_provider.dart (estado de sesión global)
    │       ├── screens/             # login_screen.dart, register_screen.dart, otp_screen.dart,
    │       │                        # forgot_password_screen.dart, reset_password_screen.dart
    │       └── widgets/
    │
    ├── profile/                     # profile-service (perfil, amigos, tags, horarios, imagen)
    ├── matching/                    # matching-service (matches, recomendaciones, categorías)
    ├── chat/                        # chat-service (REST + STOMP)
    ├── notifications/               # notification-service (lista, badge no-leídas, preferencias)
    ├── events/                      # EventService (lista, detalle, RSVP, agenda)
    ├── bienestar/                   # BienestarService (recursos, eventos, contactos emergencia)
    ├── geo/                         # GeoService (zona, catálogo)
    ├── gamification/                # GamificationService (monas, progreso, catálogo)
    ├── stats/                       # Estadisticas_Eci (dashboard personal / admin)
    └── parches/                     # Parches-Service (parches, posts, comentarios, reacciones, invitaciones)
```

Cada feature repite internamente `data/ · domain/ · presentation/` con la misma convención que `auth/`.

### Reglas de dependencia entre capas

```
presentation ──► domain ◄── data
```

- `presentation` solo conoce `domain` (entidades + interfaces de repository) vía providers.
- `data` implementa las interfaces de `domain` y es la única capa que toca Dio/STOMP.
- Nada en `features/x` importa de `features/y`. Lo compartido vive en `core/`.
- `domain/usecases` es **opcional**: solo cuando la lógica ensucia el provider o se reutiliza entre features (recomendación oficial de Flutter).

---

## 3. Decisiones técnicas

### Paquetes

| Paquete | Uso |
|---|---|
| `flutter_riverpod` | State management (providers, AsyncValue, inyección de dependencias) |
| `dio` | Cliente HTTP + interceptores |
| `go_router` | Routing declarativo + guards de autenticación |
| `flutter_secure_storage` | Tokens JWT |
| `stomp_dart_client` | WebSocket STOMP del chat (se agrega al implementar chat) |
| `equatable` | Igualdad de entidades |
| `intl` | Fechas/formatos |

¿Por qué Riverpod y no Provider? Compile-safe, sin dependencia de `BuildContext`, `AsyncValue` modela loading/error/data de forma natural y escala mejor con 11 features. Si el equipo prefiere Provider clásico, la estructura no cambia — solo la carpeta `providers/`.

### Manejo de autenticación

1. `login` → guarda `accessToken`/`refreshToken` en `flutter_secure_storage`.
2. `AuthInterceptor` (Dio) agrega `Authorization: Bearer <accessToken>` a toda petición. **TODO:** confirmar si en local también se debe enviar `X-User-Id` (los servicios lo leen; en producción lo inyectaría el gateway).
3. Respuesta `401` → intenta `POST /api/v1/auth/refresh` → reintenta la petición original → si falla, limpia sesión y redirige a login.
4. `go_router.redirect` observa `authProvider`: sin sesión → `/login`; con sesión en `/login` → `/home`.

### Manejo de errores

- `Failure` sealed class en `core/errors/`: `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `ServerFailure(message, statusCode)`, `UnknownFailure`.
- Los repositories capturan `DioException` y devuelven `Result<T>` — la UI nunca ve excepciones crudas.
- Los backends tienen `GlobalExceptionHandler` (formato de error consistente por servicio); el mapper de cada service extrae `message` del body.
- Widget `AsyncValueView` en `core/widgets/` renderiza loading/error/data uniforme en toda la app.

### Responsive

- Breakpoints en `core/utils/breakpoints.dart`: `mobile < 600`, `tablet < 1024`, `desktop ≥ 1024`.
- Decisiones de layout con `LayoutBuilder` (`constraints.maxWidth`), **no** con orientación ni tipo de dispositivo.
- `AdaptiveScaffold`: `NavigationBar` inferior en móvil ↔ `NavigationRail` lateral en pantallas anchas.
- Contenido ancho (listas, formularios) envuelto en `ConstrainedBox(maxWidth: ...)` para no estirarse en desktop.
- Listas siempre con `ListView.builder` / `GridView.builder`.

### Theme global

Material 3 con paleta oficial AlphaECI ("Paleta de color — App Matching Social"). Se definen ambos `ColorScheme` explícitos (no `fromSeed`, la marca fija cada rol):

| Rol | Light | Dark | Uso |
|---|---|---|---|
| Primario | `#1A3F6D` | `#1E4A7D` | Botones principales, accesos, acciones importantes |
| Primario claro | `#3E6FA5` | `#39639A` | Hover, enlaces, elementos interactivos |
| Acento | `#6FA8DC` | `#5D95D1` | Destacados sutiles, notificaciones, badges |
| Secundario (gris) | `#A6ADB6` | `#7B828C` | Textos secundarios, íconos, bordes, divisores |
| Fondo | `#F6F7F9` | `#0E1117` | Fondo principal de pantallas |
| Superficie | `#FFFFFF` | `#161A22` | Tarjetas, modales, contenedores |
| Texto principal | `#0F172A` | `#F1F5F9` | Textos principales, alta legibilidad |

Constantes en `core/theme/app_colors.dart` (`AppColors.primary`, `.primaryLight`, `.accent`, `.secondaryGrey`, `.background`, `.surface`, `.textPrimary` con variante light/dark). Mapeo a `ColorScheme`: `primary`, `primaryContainer`, `tertiary` (acento), `outline` (gris), `surface`, `surfaceContainerLowest`, `onSurface`. Tipografía centralizada en `app_typography.dart`. Ningún widget usa colores hard-coded: todo desde `Theme.of(context)`.

### Configuración de entornos

URLs por `--dart-define` con defaults locales en `core/config/env.dart`:

```dart
class Env {
  static const authBaseUrl = String.fromEnvironment('AUTH_URL', defaultValue: 'http://localhost:8080');
  // ... una por servicio, o una sola GATEWAY_URL cuando se confirme el gateway
}
```

**TODO:** si existe gateway Kong, colapsar todo a una sola `GATEWAY_URL`.

---

## 4. Orden de implementación sugerido

1. `core/` completo (network, errors, storage, router, theme, widgets base) + `pubspec.yaml`.
2. `features/auth` end-to-end (login/registro/OTP/refresh) — desbloquea todo lo demás.
3. `features/profile` + `AdaptiveScaffold` con navegación principal.
4. `features/matching` + `features/parches` (núcleo social).
5. `features/chat` (REST primero, STOMP después).
6. `features/events`, `notifications`, `bienestar`, `geo`.
7. `features/gamification`, `stats`.

Donde falte información del backend (formato exacto de un DTO de respuesta, paginación, etc.) se crean modelos con mock marcado `// TODO(backend): verificar contra Swagger`.
