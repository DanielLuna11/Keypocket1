import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'firebase_options.dart';

// --- INICIO DE LA APP ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
      home: AuthWrapper(),
    );
  }
}

// --- GESTIÓN DE AUTENTICACIÓN ---
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

// --- PANTALLA DE INICIO DE SESIÓN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error al iniciar sesión")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _signIn, child: const Text('Iniciar Sesión')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE REGISTRO (CON MANEJO DE ERRORES MEJORADO) ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // --- FUNCIÓN DE REGISTRO MODIFICADA ---
  Future<void> _register() async {
    // 1. Verificar que las contraseñas coinciden
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    // 2. Intentar crear el usuario en Firebase
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Si el registro es exitoso, regresar a la pantalla de inicio de sesión
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Ahora inicia sesión.')),
        );
        Navigator.pop(context); // Regresa a LoginPage
      }
    } on FirebaseAuthException catch (e) {
      // 4. Si Firebase devuelve un error, lo "atrapamos" aquí.
      String errorMessage = "Ocurrió un error desconocido.";
      
      // 5. Revisamos el CÓDIGO del error para saber qué pasó.
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este correo electrónico ya está en uso. Por favor, inicia sesión.';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del correo electrónico no es válido.';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de red. Revisa tu conexión a internet.';
          break;
      }

      // 6. Mostramos el mensaje traducido y claro al usuario.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)'), obscureText: true),
            const SizedBox(height: 16),
            TextField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirmar Contraseña'), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _register, child: const Text('Registrarse')),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Regresa a LoginPage
              },
              child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}


// --- PANTALLA PRINCIPAL Y DE DETALLES (SIN CAMBIOS) ---
class HomePage extends StatelessWidget {
  final _categoryNameController = TextEditingController();

  void _addCategory(BuildContext context) async {
    if (_categoryNameController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('categories').add({
        'name': _categoryNameController.text,
        'createdAt': Timestamp.now(),
      });

      _categoryNameController.clear();
      Navigator.of(context).pop();
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Crear Nueva Categoría'),
          content: TextField(controller: _categoryNameController, decoration: const InputDecoration(hintText: 'Nombre de la categoría'), autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => _addCategory(dialogContext), child: const Text('Crear')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Usuario no encontrado, por favor reinicie la app")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('categories').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay categorías. ¡Añade una!"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailsPage(
                        categoryId: doc.id,
                        categoryName: doc['name'],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        tooltip: 'Crear Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryDetailsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailsPage({super.key, required this.categoryId, required this.categoryName});

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  void _addCredential() async {
    if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Debes iniciar sesión.')));
        }
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('categories').doc(widget.categoryId)
            .collection('credentials')
            .add({
              'username': _usernameController.text,
              'password': _passwordController.text,
            });

        _usernameController.clear();
        _passwordController.clear();
        FocusScope.of(context).unfocus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Guardado en la nube con éxito!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar en Firebase: $e'),
              backgroundColor: Colors.red,
            )
          );
        }
      }
    }
  }

  void _showCredentialDetails(String username, String password) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Credencial Completa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: $username'),
            const SizedBox(height: 8),
            Text('Contraseña: $password'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar'))],
      ),
    );
  }

  void _showAdminPasswordPrompt(String username, String password) {
    _adminPasswordController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verificar Administrador'),
        content: TextField(controller: _adminPasswordController, decoration: const InputDecoration(labelText: 'Contraseña de la cuenta'), obscureText: true, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final localPasswordCheck = _adminPasswordController.text == 'password'; // Simplificado
              Navigator.of(dialogContext).pop();
              if (localPasswordCheck) {
                _showCredentialDetails(username, password);
              } else {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña incorrecta')));
                }
              }
            },
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Usuario no encontrado")));

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Correo o Usuario')),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 24),
            Center(child: ElevatedButton(onPressed: _addCredential, child: const Text('Guardar Credencial'))),
            const Divider(height: 40),
            const Text('Credenciales Guardadas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(user.uid)
                    .collection('categories').doc(widget.categoryId)
                    .collection('credentials')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error al cargar credenciales: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No hay credenciales guardadas."));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text('Usuario: ${data['username']}'),
                          subtitle: const Text('Contraseña: ********'),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'Ver credencial',
                            onPressed: () => _showAdminPasswordPrompt(data['username'], data['password']),
                          ),
                        ),
                      );
                    }).toList(),
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