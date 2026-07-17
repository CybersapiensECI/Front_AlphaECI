# Guía del desarrollador — Front_AlphaECI

Guía desde cero. No necesitas saber Flutter para empezar aquí.

---

## 1. Instalar herramientas

### 1.1 Flutter SDK

1. Descarga el SDK: https://docs.flutter.dev/get-started/install (elige tu sistema operativo).
2. Descomprime en una ruta sin espacios (ej. `C:\dev\flutter`).
3. Agrega `C:\dev\flutter\bin` al `PATH`.
4. Verifica:

```bash
flutter --version
flutter doctor
```

`flutter doctor` te dice qué falta. No necesitas TODO en verde; con esto basta:

- **Para probar en navegador (lo más fácil):** solo Chrome.
- **Para Android:** Android Studio + un emulador (Android Studio → Device Manager → Create Device).
- **Para app de escritorio Windows:** Visual Studio con carga "Desktop development with C++".

### 1.2 Editor

VS Code + extensiones **Flutter** y **Dart** (instalan autocompletado, hot reload desde el editor, debugger).

---

## 2. Preparar el proyecto

```bash
cd Front_AlphaECI
flutter pub get        # descarga las dependencias del pubspec.yaml
```

`pubspec.yaml` es el equivalente a `package.json`/`pom.xml`: ahí se declaran las dependencias. Cada vez que alguien agregue una, vuelve a correr `flutter pub get`.

---

## 3. Correr la app

### Opción A — Navegador (recomendada para empezar)

```bash
flutter run -d chrome
```

### Opción B — Emulador Android

```bash
flutter emulators                # lista emuladores
flutter emulators --launch <id>  # arranca uno
flutter run                      # corre en el dispositivo activo
```

### Opción C — Escritorio Windows

```bash
flutter run -d windows
```

### Ver los cambios (hot reload)

Con la app corriendo, edita cualquier archivo `.dart` y:

- Presiona **`r`** en la terminal → **hot reload**: aplica el cambio en ~1s sin perder el estado de la app.
- Presiona **`R`** → **hot restart**: reinicia la app completa (necesario si cambiaste `main.dart`, providers globales o constantes).
- Presiona **`q`** → salir.

En VS Code, con F5 (debug) el hot reload es automático al guardar.

---

## 3.5 Modo demo (sin backends)

Para ver TODA la app sin levantar ningún servicio:

```bash
flutter run -d windows --dart-define=DEMO=true
```

Cualquier correo/contraseña sirve en el login. Los datos (personas, parches, eventos, notificaciones) son de muestra — repositorios mock marcados `TODO(demo)` en `data/repositories/mock_*.dart`. La cinta "DEMO" en la esquina indica que está activo. Sin el flag, la app usa los backends reales.

## 4. Conectar con los backends

Los servicios corren localmente (cada repo tiene `Dockerfile`; identity tiene `docker-compose.yml`). Las URLs se pasan al front con `--dart-define`:

```bash
flutter run -d chrome --dart-define=AUTH_URL=http://localhost:8080
```

Sin `--dart-define` se usan los defaults de `lib/core/config/env.dart`.

> Nota web/CORS: si el navegador bloquea las peticiones, es CORS del backend, no un bug del front. Prueba primero en Windows/emulador, o habilita CORS en el servicio.

---

## 5. Cómo está organizado el código

Lee `docs/ARQUITECTURA.md` para el detalle de capas y `docs/FEATURES.md` para el mapa feature por feature. Resumen mental:

```
lib/core/      → lo compartido: HTTP, errores, rutas, tema, widgets comunes
lib/features/  → una carpeta por dominio (auth, chat, events, parches...)
```

Dentro de cada feature hay tres capas — la regla de oro:

| Capa | Qué contiene | Qué NO debe hacer |
|---|---|---|
| `presentation/` | Pantallas, widgets, providers (estado) | Llamar HTTP directo |
| `domain/` | Entidades e interfaces de repository | Importar Dio o JSON |
| `data/` | Modelos JSON, servicios API, implementación de repositories | Importar widgets |

Flujo de una petición: **Screen → Provider → Repository (interfaz) → RepositoryImpl → ApiService → Dio → backend**, y de vuelta el resultado llega como `Result<T>` (éxito o `Failure`), nunca como excepción cruda.

---

## 6. Cómo agregar una funcionalidad nueva

Ejemplo: mostrar la lista de eventos (`GET /events` de EventService).

1. **Modelo** — `features/events/data/models/event_model.dart`: clase con `fromJson`, campos espejo de la respuesta real (verifica en el controlador o Swagger del backend — no inventes campos).
2. **Service** — `features/events/data/services/event_api_service.dart`: método `Future<List<EventModel>> getEvents()` que llama a Dio.
3. **Repository** — interfaz en `domain/repositories/`, implementación en `data/repositories/` que convierte modelo → entidad y errores → `Failure`.
4. **Provider** — `presentation/providers/events_provider.dart`: expone `AsyncValue<List<Event>>`.
5. **Screen** — `presentation/screens/events_screen.dart`: consume el provider y pinta con `AsyncValueView`.
6. **Ruta** — registra el path en `core/router/routes.dart` y `app_router.dart`.

---

## 7. Comandos útiles

```bash
flutter pub get              # instalar dependencias
flutter run -d chrome        # correr en Chrome
flutter analyze              # linter: correr antes de cada commit
flutter test                 # tests
dart format lib/             # formatear código
flutter clean                # borrar caché de build (cuando algo raro pasa)
```

---

## 8. Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| `Target of URI doesn't exist` | Falta `flutter pub get` |
| Cambié código y no se ve | Hot reload no cubre `main()` ni estado inicial → usa `R` (hot restart) |
| Errores raros de build | `flutter clean && flutter pub get` |
| Peticiones fallan solo en web | CORS del backend |
| `flutter doctor` marca Android en rojo pero yo uso Chrome | Ignorable: cada plataforma solo se necesita si compilas para ella |
