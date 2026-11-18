
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';
import 'pages/product_page.dart';
import 'pages/inventory_view_page.dart';
import 'pages/stock_in_page.dart';
import 'models/product_model.dart';
import 'services/product_service.dart';
import 'pages/stock_in_history_page.dart';
import 'pages/sales_page.dart';
import 'pages/sales_history_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const StockMateApp());
}

const navy = Color(0xFF173B67);
const background = Color(0xFFF3F6FB);

final DatabaseReference database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://stockmate-1a9c5-default-rtdb.firebaseio.com',
).ref();

class StockMateApp extends StatelessWidget {
  const StockMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StockMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}

// ================= LOGIN PAGE =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'Admin';
  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Email dan password wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Data pengguna tidak ditemukan.');
      }

      final snapshot =
          await database.child('users/${user.uid}').get();

      if (!snapshot.exists || snapshot.value == null) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage('Profil pengguna belum terdaftar di database.');
        return;
      }

      final profile = Map<String, dynamic>.from(
        snapshot.value as Map,
      );

      final databaseRole =
          (profile['role'] ?? '').toString().toLowerCase();

      final storeId =
          (profile['storeId'] ?? '').toString();

      final email =
          (profile['email'] ?? user.email ?? '').toString();

      if (databaseRole != 'admin' &&
          databaseRole != 'kasir') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage('Role pengguna tidak valid.');
        return;
      }

      if (selectedRole.toLowerCase() != databaseRole) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage(
          'Akun ini terdaftar sebagai '
          '${databaseRole.toUpperCase()}, bukan $selectedRole.',
        );
        return;
      }

      if (storeId.isEmpty) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage('Identitas toko belum terdaftar.');
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            role: databaseRole == 'admin' ? 'Admin' : 'Kasir',
            storeId: storeId,
            email: email,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-not-found':
          message = 'Akun tidak ditemukan.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Email atau password salah.';
          break;
        case 'user-disabled':
          message = 'Akun ini telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          message = 'Periksa koneksi internet Anda.';
          break;
        default:
          message = 'Login gagal: ${e.message ?? e.code}';
      }

      if (mounted) showMessage(message);
    } on FirebaseException catch (e) {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        showMessage(
          'Gagal membaca database: ${e.message ?? e.code}',
        );
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();

      if (mounted) showMessage('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: navy,
                    size: 65,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'StockMate',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sistem Manajemen Stok dan Penjualan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Silakan masuk ke akun StockMate Anda.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Masuk sebagai',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.people_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'Kasir',
                        child: Text('Kasir'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Masukkan email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Password',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 23,
                              width: 23,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'MASUK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'StockMate © 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= DASHBOARD PAGE =================

class DashboardPage extends StatelessWidget {
  final String role;
  final String storeId;
  final String email;

  const DashboardPage({
    super.key,
    required this.role,
    required this.storeId,
    required this.email,
  });

  bool get isAdmin => role == 'Admin';

  List<Map<String, dynamic>> get menus {
    if (isAdmin) {
      return [
        {
          'title': 'Dashboard',
          'icon': Icons.dashboard_rounded,
          'description': 'Ringkasan aktivitas toko',
        },
        {
          'title': 'Data Barang',
          'icon': Icons.inventory_2_rounded,
          'description': 'Kelola data produk',
        },
        {
          'title': 'Barang Masuk',
          'icon': Icons.add_box_rounded,
          'description': 'Catat stok masuk',
        },
        {
          'title': 'Riwayat Barang Masuk',
          'icon': Icons.history_rounded,
          'description': 'Lihat catatan stok masuk',
        },
        {
          'title': 'Riwayat Penjualan',
          'icon': Icons.receipt_long_rounded,
          'description': 'Lihat transaksi toko',
        },
        {
          'title': 'Laporan',
          'icon': Icons.bar_chart_rounded,
          'description': 'Laporan penjualan dan stok',
        },
      ];
    }

    return [
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard_rounded,
        'description': 'Ringkasan aktivitas kasir',
      },
      {
        'title': 'Data Barang',
        'icon': Icons.inventory_2_rounded,
        'description': 'Lihat daftar barang dan stok',
      },
      {
        'title': 'Penjualan',
        'icon': Icons.point_of_sale_rounded,
        'description': 'Buat transaksi baru',
      },
      {
        'title': 'Riwayat Penjualan',
        'icon': Icons.receipt_long_rounded,
        'description': 'Lihat transaksi sebelumnya',
      },
    ];
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // ================= NAVIGASI MENU =================

  void openMenu(BuildContext context, String menuTitle) {
    if (menuTitle == 'Data Barang') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isAdmin
              ? ProductPage(storeId: storeId)
              : InventoryViewPage(storeId: storeId),
        ),
      );
      return;
    }

    if (menuTitle == 'Barang Masuk' && isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockInPage(
            storeId: storeId,
          ),
        ),
      );
      return;
    }

    if (menuTitle == 'Riwayat Barang Masuk' && isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockInHistoryPage(
            storeId: storeId,
          ),
        ),
      );
      return;
    }

    // Penjualan hanya untuk Kasir.
    if (menuTitle == 'Penjualan' && !isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SalesPage(
            storeId: storeId,
            email: email,
          ),
        ),
      );
      return;
    }

    // Riwayat Penjualan untuk Admin dan Kasir.
    if (menuTitle == 'Riwayat Penjualan') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SalesHistoryPage(
            storeId: storeId,
          ),
        ),
      );
      return;
    }

    // Menu lain akan dibuat pada tahap berikutnya.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Menu $menuTitle akan kita buat pada tahap berikutnya.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productService = ProductService(storeId: storeId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded),
            SizedBox(width: 10),
            Text(
              'StockMate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                role,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard $role',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26364A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? 'Selamat datang! Kelola persediaan dan aktivitas toko Anda.'
                      : 'Selamat bekerja! Siap melayani transaksi pelanggan.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Akun: $email',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ID Toko: $storeId',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Ringkasan Stok Toko',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                StreamBuilder<List<ProductModel>>(
                  stream: productService.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Gagal memuat ringkasan stok.',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final products = snapshot.data!;

                    final lowStock = products.where(
                      (product) =>
                          product.stok <= product.stokMinimum,
                    ).length;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final count =
                            constraints.maxWidth > 700 ? 4 : 2;

                        final cardWidth =
                            (constraints.maxWidth -
                                    (count - 1) * 12) /
                                count;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SummaryCard(
                              width: cardWidth,
                              title: 'Total Barang',
                              value: products.length.toString(),
                              icon: Icons.inventory_2,
                              color: Colors.blue,
                            ),
                            SummaryCard(
                              width: cardWidth,
                              title: 'Stok Menipis',
                              value: lowStock.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            if (isAdmin)
                              SummaryCard(
                                width: cardWidth,
                                title: 'Penjualan Hari Ini',
                                value: 'Rp0',
                                icon: Icons.point_of_sale,
                                color: Colors.green,
                              ),
                            if (isAdmin)
                              SummaryCard(
                                width: cardWidth,
                                title: 'Transaksi',
                                value: '0',
                                icon: Icons.receipt_long,
                                color: Colors.purple,
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final count =
                        constraints.maxWidth > 800
                            ? 3
                            : constraints.maxWidth > 500
                                ? 2
                                : 1;

                    final cardWidth =
                        (constraints.maxWidth -
                                (count - 1) * 14) /
                            count;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: menus.map((menu) {
                        return SizedBox(
                          width: cardWidth,
                          child: MenuCard(
                            title: menu['title'],
                            description: menu['description'],
                            icon: menu['icon'],
                            onTap: () {
                              openMenu(
                                context,
                                menu['title'],
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'StockMate © 2026',
                    style: TextStyle(color: Colors.grey),
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

// ================= SUMMARY CARD =================

class SummaryCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= MENU CARD =================

class MenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: navy,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
