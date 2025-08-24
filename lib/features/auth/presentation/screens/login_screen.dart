import 'package:flutter/material.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../prestataire/presentation/screens/prestataire_dashboard_screen.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';
import 'register_screen.dart';
import 'forget_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo and Title
                Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'assets/images/logo1.png',
                        width: 120, // Choisis la taille souhaitée
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text(
                      'Task Manager Pro',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestionnaire de tâches collaboratives',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Auth Form
                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Lien Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgetPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 8),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await signIn(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Connexion' : 'S’inscrire',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 16),

                // Toggle Mode Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    _isLoginMode
                        ? 'Pas de compte ? S\'inscrire'
                        : 'Déjà un compte ? Se connecter',
                  ),
                ),

                const SizedBox(height: 24),

                // Demo Login Button
              
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> signIn(String email, String password) async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('=== DÉBUT DE LA CONNEXION ===');
      print('Email: $email');

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Connexion réussie : récupérer les données utilisateur
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        print('Utilisateur connecté avec UID: ${firebaseUser.uid}');

        // Récupérer les données utilisateur depuis Firestore
        final userModel = await _firebaseService.getUserModel(firebaseUser.uid);

        if (userModel != null) {
          print('Données utilisateur récupérées:');
          print('Nom: ${userModel.displayName}');
          print('Rôle: ${userModel.role}');

          if (mounted) {
            // Rediriger selon le rôle
            if (userModel.role == UserRole.admin) {
              print('Redirection vers le dashboard admin');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(currentUser: userModel),
                ),
              );
            } else if (userModel.role == UserRole.prestataire) {
              print('Redirection vers le dashboard prestataire');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      PrestataireDashboardScreen(currentUser: userModel),
                ),
              );
            } else {
              // Pour les autres rôles (member, guest), utiliser le dashboard normal
              print('Redirection vers le dashboard normal');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(currentUser: userModel),
                ),
              );
            }
          }
        } else {
          print('ERREUR: Impossible de récupérer les données utilisateur');
          _showErrorDialog(
              'Impossible de récupérer les données utilisateur. Veuillez réessayer.');
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Code: ${e.code}, Message: ${e.message}');
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = "Aucun utilisateur trouvé pour cet email.";
          break;
        case 'wrong-password':
          errorMsg = "Mot de passe incorrect.";
          break;
        case 'invalid-email':
          errorMsg = "L'email n'est pas valide.";
          break;
        case 'user-disabled':
          errorMsg = "Ce compte a été désactivé.";
          break;
        default:
          errorMsg = "Une erreur est survenue. Veuillez réessayer.";
      }
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Erreur de connexion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _demoLogin() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   // Simuler un délai de connexion
  //   await Future.delayed(const Duration(seconds: 1));

  //   // Utilisateur admin démo
  //   final user = UserModel.demoUsers.firstWhere(
  //     (u) => u.role == UserRole.admin,
  //     orElse: () => UserModel.demoUsers.first,
  //   );

  //   if (mounted) {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     // Navigation vers le dashboard avec UserModel
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (_) => DashboardScreen(currentUser: user)),
  //     );
  //   }
  // }

  void _showErrorDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erreur de connexion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
