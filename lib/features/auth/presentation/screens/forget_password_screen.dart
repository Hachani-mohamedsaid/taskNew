import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _iconAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconAnim = Tween<double>(begin: 0.7, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_animController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      setState(() => _sent = true);
      _animController.forward();
      // Ici, tu peux appeler ton backend pour envoyer le mail de réinitialisation
    }
  }

  Future<void> resetPassword(String email) async {
    setState(() {
      _isLoading = true;
      _sent = false;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _sent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(""),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'invalid-email':
          errorMsg = "L'email n'est pas valide.";
          break;
        default:
          errorMsg = "Une erreur est survenue. Veuillez réessayer.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      print('Méthodes pour $email : $methods');
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe3f0ff), Color(0xFFf8fafc)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shadowColor: Colors.blueAccent.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: Colors.blueAccent, width: 2)),
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: _sent
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _iconAnim,
                              child: const Icon(Icons.mark_email_read,
                                  color: Colors.blue, size: 64),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Lien envoyé !',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.blueAccent),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Un lien de réinitialisation a été envoyé à votre adresse email.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.15),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFdbeafe),
                                        Color(0xFFf0f9ff)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  child: Image.asset(
                                    'assets/images/logo1.png',
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: Text(
                                  'Task Manager Pro',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                        letterSpacing: 1.2,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Mot de passe oublié ? 😕',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
                                style: TextStyle(fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Champ requis';
                                  }
                                  final emailRegex =
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!emailRegex.hasMatch(v)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          final email =
                                              _emailController.text.trim();
                                          final methods = await FirebaseAuth
                                              .instance
                                              .fetchSignInMethodsForEmail(
                                                  email);
                                          print(
                                              'Méthodes pour $email : $methods');
                                          // if (methods.isEmpty) {
                                          //   ScaffoldMessenger.of(context)
                                          //       .showSnackBar(
                                          //     const SnackBar(content: Text("Cet email n'existe pas.")),
                                          //   );
                                          //   return;
                                          // }
                                          await resetPassword(email);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF9333EA)
                                      ], // bleu → violet
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    constraints:
                                        const BoxConstraints(minHeight: 48),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                color: Colors.white),
                                          )
                                        : const Text(
                                            'Envoyer le lien de réinitialisation',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
