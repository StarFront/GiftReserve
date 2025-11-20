import 'package:flutter/material.dart';
import 'package:giflist/services/auth_api.dart';
import 'package:giflist/screens/add_gift_screen.dart';
import 'package:giflist/screens/view_gifts_screen.dart';
import 'package:giflist/screens/view_gifts_guest_screen.dart';
import 'package:giflist/screens/view_my_reservations_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthApi _authApi = AuthApi();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = _authApi.getCurrentUser();
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('GiftList'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authApi.logout();
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: isAdmin ? _buildAdminDashboard(context, user!.name) : _buildGuestDashboard(context, user!.name),
    );
  }
  Widget _buildAdminDashboard(BuildContext context, String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  '¡Bienvenido!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona tus regalos de manera fácil y organizada',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Agregar Regalo Card
          _buildActionCard(
            context,
            icon: Icons.add,
            title: 'Agregar Regalo',
            subtitle: 'Añade un nuevo regalo a tu lista',
            gradient: LinearGradient(
              colors: [
                Colors.purple[400]!,
                Colors.purple[600]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddGiftScreen(),
                  ),
                );
            },
          ),
          const SizedBox(height: 16),

          // Ver Regalos Card
          _buildActionCard(
            context,
            icon: Icons.card_giftcard,
            title: 'Ver Regalos',
            subtitle: 'Explora tu colección de regalos',
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE91E8C),
                const Color(0xFFD91B7F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewGiftsScreen()),
              );
            },
          ),
          const SizedBox(height: 56),

          // Decorative Heart
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple[100],
              ),
              child: Center(
                child: Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.purple[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestDashboard(BuildContext context, String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  '¡Hola, $name!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubre regalos y haz tus reservas',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Ver Regalos Card
          _buildActionCard(
            context,
            icon: Icons.card_giftcard,
            title: 'Ver Regalos',
            subtitle: 'Explora listas de regalos disponibles',
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE91E8C),
                const Color(0xFFD91B7F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewGiftsGuestScreen()),
              );
            },
          ),
          const SizedBox(height: 16),

          // Mis Reservas Card
          _buildActionCard(
            context,
            icon: Icons.check_circle,
            title: 'Mis Reservas',
            subtitle: 'Gestiona tus regalos reservados',
            gradient: LinearGradient(
              colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewMyReservationsScreen()));
            },
          ),
          const SizedBox(height: 56),

          // Decorative Heart
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink[100],
              ),
              child: Center(
                child: Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.pink[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
