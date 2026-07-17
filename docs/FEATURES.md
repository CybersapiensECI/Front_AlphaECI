# Mapa de features — AlphaECI

Una fila por feature: qué hace, sus pantallas, providers y el servicio backend que consume. Los endpoints exactos están en [ARQUITECTURA.md §5](ARQUITECTURA.md#5-endpoints-por-servicio).

Cada feature sigue la misma estructura de tres capas (`data/ · domain/ · presentation/`). Los repositorios tienen implementación real (`*_repository_impl.dart`) y mock (`mock_*_repository.dart`); el provider elige según `Env.demoMode`.

---

## home — el shell

No consume backend; monta a los demás. `HomeScreen` es un `AdaptiveScaffold` con siete tabs: **Inicio · Parches · Descubrir · Matches · Eventos · Monas · Perfil**. `homeTabProvider` (un `StateProvider<int>`) guarda el tab activo, de modo que se puede navegar a un tab desde fuera (p. ej. tocar una notificación). El AppBar lleva accesos a Chats, Mapa de parches y la campana de notificaciones con badge, más el menú de cerrar sesión.

## auth — identity-service

Registro con verificación por OTP, login, refresh automático y recuperación de contraseña. Es el feature que desbloquea a todos los demás.

- **Pantallas** — `login`, `register`, `otp`, `complete_profile`, `forgot_password`.
- **Providers** — `authControllerProvider` (`NotifierProvider` con el estado global de sesión: `unknown` / `unauthenticated` / `authenticated`), más el wiring del repo y del `AuthApiService`.
- El `AuthController` también escucha el `SessionExpiryBus` para hacer logout cuando el refresh falla en el interceptor.

## profile — profile-service

Perfil propio, perfil público de otros usuarios, edición y tags/intereses.

- **Pantallas** — `profile` (propio, dentro del tab Perfil), `public_profile` (de otro usuario, ruta `/users/:id`), `edit_profile`.
- **Provider** — `profile_provider`.
- Expone `getProfilesByIds` (batch), que el feed usa para resolver los autores de todos los posts en una sola llamada.

## matching — matching-service

Descubrir personas afines y gestionar matches enviados/recibidos.

- **Pantallas** — `discovery` (deck de swipe, widget `swipe_deck.dart`), `matches` (enviados y recibidos).
- **Provider** — `matching_provider`.
- Las recomendaciones vienen con score desde el backend (`/recommendations/{userId}/scores`).

## parches — Parches-Service

*Parches* = planes en el campus. Crear, buscar, unirse, y publicar posts dentro de un parche con comentarios y reacciones.

- **Pantallas** — `parches` (lista con filtros, tab Parches), `create_parche`, `parche_detail`.
- **Widgets** — `comments_sheet`, `friend_picker`, `post_composer_sheet` (compositor de post, con subida de foto a Firebase Storage).
- **Providers** — `parche_provider`, `comments_provider`.

## feed — compuesto (parches + profile)

El tab Inicio: red social. Agrega los posts de todos los parches visibles, resuelve sus autores en batch y los ordena por fecha. No tiene backend propio; **compone** `parches/` y `profile/` (una de las dos excepciones a la regla de no cruzar features).

- **Pantalla** — `feed_screen`; widget `publication_card`.
- **Providers** — `publicationsProvider` (el feed agregado), `feedCategoryProvider` (filtro), `likedPostsProvider` (likes optimistas locales — el backend aún no expone contadores), `publishableParcheProvider` (el parche donde el usuario puede publicar *ahora*: miembro, `ACTIVE` y hoy).

## events — EventService

Eventos institucionales con RSVP y agenda personal.

- **Pantalla** — `events_screen` (tab Eventos).
- **Provider** — `event_provider`.
- RSVP: `POST` confirma, `PUT` cancela.

## chat — chat-service (REST + STOMP)

Chats 1-a-1 (derivados de conexiones/matches) y chat grupal de un parche, en tiempo real.

- **Pantallas** — `chats` (lista de conversaciones), `chat_room` (sala; tiene constructor `.group()` para el chat del parche).
- **Provider** — `chat_provider`.
- REST para historial paginado y lista de conexiones; **STOMP sobre WebSocket** para el tiempo real: envía a `/app/chat/{id}/send`, se suscribe a `/topic/parche/{id}/messages`. El WebSocket va directo al chat-service (`CHAT_WS_URL`), no por el gateway.

## notifications — notification-service

Lista de notificaciones y el badge de no-leídas de la campana.

- **Pantalla** — `notifications_screen`.
- **Providers** — `notification_provider`, con `unreadCountProvider` alimentando el badge del AppBar.

## bienestar — BienestarService

Recursos de bienestar universitario, eventos de bienestar y contactos de emergencia.

- **Pantalla** — `wellbeing_screen`.
- **Provider** — `wellbeing_provider`.

## geo — GeoService

Mapa del campus (OpenStreetMap vía `flutter_map`, sin API key) con la zona del usuario.

- **Pantalla** — `zone_screen` (acceso desde el ícono de mapa del AppBar).
- Sin provider dedicado: la pantalla usa `zone_repository.dart` directamente. Guarda la zona (`POST /`), lee la propia (`GET /me`) y el catálogo (`GET /catalog`).
- Lugares del campus predefinidos en [lib/core/constants/campus_places.dart](../lib/core/constants/campus_places.dart).

## gamification — GamificationService

Álbum de *monas* (35 medallas). Se muestra como el tab Monas y como pantalla propia.

- **Pantalla** — `monas_screen` (expone `MonasBody`, embebido en el tab Monas del shell).
- **Widgets** — `mona_medal`, `mona_styles`, `locked_overlay` (las no desbloqueadas salen atenuadas).
- **Provider** — `gamification_provider`.
- Assets en `assets/monas/`. Descripción visual de cada medalla en [DESCRIPCION_MEDALLAS.md](DESCRIPCION_MEDALLAS.md).

## stats — Estadisticas_Eci

Dashboard personal: XP, nivel, monas desbloqueadas, eventos asistidos, parches. El backend es un BFF que ya devuelve todo agregado.

- **Pantalla** — `dashboard_screen`.
- Sin provider dedicado: la pantalla usa `stats_repository.dart` directamente. Charts en `core/widgets/charts.dart`.

---

## Cómo agregar un feature

1. **Modelo** en `data/models/` con `fromJson`, campos espejo de la respuesta real (verifica contra el controlador o Swagger del backend, no inventes campos).
2. **Service** en `data/services/`: métodos que llaman a Dio y devuelven modelos.
3. **Repository**: interfaz en `domain/repositories/`, implementación real en `data/repositories/` (convierte modelo → entidad y `DioException` → `Failure`) y un mock al lado.
4. **Provider** en `presentation/providers/`: expone `AsyncValue<...>` y elige repo real/mock según `Env.demoMode`.
5. **Pantalla** en `presentation/screens/`: consume el provider con `AsyncValueView`.
6. **Ruta**: registra el path en `core/router/routes.dart` y en `app_router.dart`.

Detalle paso a paso en [GUIA_DESARROLLADOR.md §6](GUIA_DESARROLLADOR.md).
