import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keypocket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
    );
  }
}

// Modelo para las credenciales
class Credential {
  final String username;
  final String password;

  Credential({required this.username, required this.password});
}

// Modelo para las categorías
class Category {
  final String name;
  final List<Credential> credentials;

  Category({required this.name, List<Credential>? credentials})
      : credentials = credentials ?? [];
}

// Pantalla de Inicio de Sesión
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    if (_usernameController.text == 'admin' &&
        _passwordController.text == 'password') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Usuario (admin)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña (password)'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla Principal
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Category> _categories = [];
  final _categoryNameController = TextEditingController();

  void _addCategory() {
    if (_categoryNameController.text.isNotEmpty) {
      setState(() {
        // --- LÍNEA CORREGIDA ---
        _categories.add(Category(name: _categoryNameController.text));
        _categoryNameController.clear();
      });
      Navigator.of(context).pop();
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Nueva Categoría'),
          content: TextField(
            controller: _categoryNameController,
            decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCategoryDetails(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailsPage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ListTile(
            title: Text(category.name),
            trailing: ElevatedButton(
              onPressed: () => _navigateToCategoryDetails(category),
              child: const Text('Guardar Credenciales'),
            ),
            onTap: () => _navigateToCategoryDetails(category),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
        tooltip: 'Crear Categoría',
      ),
    );
  }
}

// Pantalla de Detalles de la Categoría
class CategoryDetailsPage extends StatefulWidget {
  final Category category;

  const CategoryDetailsPage({super.key, required this.category});

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _addCredential() {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      setState(() {
        widget.category.credentials.add(
          Credential(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
        _usernameController.clear();
        _passwordController.clear();
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credencial guardada con éxito')),
      );
    }
  }

  // Muestra las credenciales si la contraseña de admin es correcta
  void _showCredentialDetails(Credential credential) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Credencial Completa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${credential.username}'),
              const SizedBox(height: 8),
              Text('Contraseña: ${credential.password}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Pide la contraseña del admin antes de mostrar los detalles
  void _showAdminPasswordPrompt(Credential credential) {
    _adminPasswordController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verificar Administrador'),
          content: TextField(
            controller: _adminPasswordController,
            decoration: const InputDecoration(labelText: 'Contraseña de admin'),
            obscureText: true,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo de contraseña
                if (_adminPasswordController.text == 'password') {
                  _showCredentialDetails(credential);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseña incorrecta')),
                  );
                }
              },
              child: const Text('Ver'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _addCredential,
                child: const Text('Guardar Credencial'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Credenciales Guardadas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.category.credentials.length,
                itemBuilder: (context, index) {
                  final credential = widget.category.credentials[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text('Usuario: ${credential.username}'),
                      subtitle: const Text('Contraseña: ********'),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'Ver credencial',
                        onPressed: () => _showAdminPasswordPrompt(credential),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}