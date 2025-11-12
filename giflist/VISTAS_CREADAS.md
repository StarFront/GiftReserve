# GiftList - Frontend Flutter

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada y navegación principal
├── screens/
│   ├── auth_screen.dart     # Login/Registro unificado
│   └── home_screen.dart     # Pantalla principal después de login
├── models/
│   └── user_model.dart      # Modelo de datos del usuario
├── services/
│   └── auth_service.dart    # Servicio de autenticación
└── widgets/
    └── (widgets reutilizables irán aquí)
```

## 🚀 Vistas Completadas

### 1. **Auth Screen** (Login/Registro)
- ✅ Interfaz unificada con TabBar
- ✅ Tab de "Iniciar Sesión"
- ✅ Tab de "Registrarse"
- ✅ Validaciones de formulario
- ✅ Mensajes de error
- ✅ Loading states
- ✅ UI moderna y responsive

**Características:**
- Email y contraseña para login
- Nombre, email, contraseña y confirmación para registro
- Validación de contraseñas mínimo 6 caracteres
- Validación de email
- Contraseñas ocultas/visibles con toggle
- Información para invitados

### 2. **Home Screen**
- ✅ Navegación post-login
- ✅ Diferenciación entre Host e Invitado
- ✅ Botones de acceso rápido
- ✅ Menú de logout

## 📝 Vistas por Implementar

### Para Host:
- [ ] **Agregar Regalo** - Formulario para crear nuevo regalo
- [ ] **Mi Lista de Regalos** - Vista con CRUD de regalos
- [ ] **Reservas Recibidas** - Ver quién reservó qué

### Para Invitado:
- [ ] **Ver Regalos** - Lista de regalos disponibles
- [ ] **Mis Reservas** - Regalos que he reservado
- [ ] **Reservar Regalo** - Botón para reservar
- [ ] **Cancelar Reserva** - Opción para cancelar

## 🔧 Integración con Backend

### Archivo: `lib/services/auth_service.dart`

Actualmente usa mocks. Para integrar con tu backend AWS:

```dart
// Descomenta y actualiza las llamadas HTTP en:
// - login()
// - register()

// Ejemplo de integración:
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://tu-backend-url.com/api';

// En login():
final response = await http.post(
  Uri.parse('$baseUrl/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
  }),
);
```

## 🎨 Temas y Colores

El app usa Material Design 3 con:
- **Color Primario**: Deep Purple
- **Tema**: Tema claro adaptativo

Para personalizar, edita en `main.dart`:
```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  useMaterial3: true,
),
```

## 📦 Dependencias Necesarias

En `pubspec.yaml` (ya debería estar):
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # Para llamadas HTTP al backend
  # Próximamente: provider, get_it, etc.
```

## 🏃 Cómo Ejecutar

```bash
flutter pub get
flutter run
```

## 🔐 Flujo de Autenticación

1. **Usuario abre app** → AuthWrapper verifica si está autenticado
2. **No autenticado** → Muestra AuthScreen
3. **Selecciona Login/Registro** → Completa datos
4. **Envía datos** → AuthService hace llamada al backend
5. **Backend retorna datos usuario** → Se guarda usuario en AuthService
6. **Navega a HomeScreen** → Según el rol, muestra opciones diferentes

## 🗂️ Próximas Vistas a Crear

Para continuar, podemos crear:

1. **Gift Management Screen** (Host)
   - Agregar regalo con nombre, descripción, prioridad, cantidad
   - Editar regalo
   - Eliminar regalo
   - Ver reservas por regalo

2. **Gifts List Screen** (Invitado)
   - Filtrar por host
   - Búsqueda
   - Detalles de regalo
   - Botón reservar

3. **My Reservations Screen** (Invitado)
   - Mis reservas activas
   - Opción para cancelar
   - Historial

## 📱 Responsividad

Todas las vistas están diseñadas para ser responsive en:
- Móviles (Portrait y Landscape)
- Tablets
- Pantallas grandes

## 💡 Notas Importantes

- El `AuthService` usa un singleton simple. Si necesitas persistent storage, considera usar `shared_preferences` o `flutter_secure_storage`
- Los errores del backend se mostrarán en rojo en la UI
- Para logout, se puede hacer desde el menú en HomeScreen

---

**Próximo paso**: ¿Quieres que continúe con las vistas de gestión de regalos para el Host o la lista de regalos para el Invitado?
