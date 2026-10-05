import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void main() {
  runApp(const FoodieGoApp());
}

class FoodItem {
  final String name;
  final String description;
  final double price;
  final String emoji;

  const FoodItem({
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
  });
}

class Restaurant {
  final String name;
  final String cuisine;
  final double rating;
  final String emoji;
  final List<FoodItem> menu;

  const Restaurant({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.emoji,
    required this.menu,
  });
}

const restaurants = <Restaurant>[
  Restaurant(
    name: 'Spice Garden',
    cuisine: 'Biryani • Indian',
    rating: 4.6,
    emoji: '🍛',
    menu: [
      FoodItem(name: 'Chicken Biryani', description: 'Aromatic basmati rice with tender chicken.', price: 189, emoji: '🍗'),
      FoodItem(name: 'Paneer Biryani', description: 'Fragrant rice with spicy paneer.', price: 169, emoji: '🧀'),
      FoodItem(name: 'Butter Naan', description: 'Soft naan finished with butter.', price: 49, emoji: '🫓'),
    ],
  ),
  Restaurant(
    name: 'Burger Hub',
    cuisine: 'Burgers • Fast Food',
    rating: 4.4,
    emoji: '🍔',
    menu: [
      FoodItem(name: 'Classic Chicken Burger', description: 'Crispy chicken, lettuce and signature sauce.', price: 149, emoji: '🍔'),
      FoodItem(name: 'Veg Supreme Burger', description: 'Crispy veg patty with cheese and fresh veggies.', price: 129, emoji: '🥬'),
      FoodItem(name: 'French Fries', description: 'Golden and crispy salted fries.', price: 89, emoji: '🍟'),
    ],
  ),
  Restaurant(
    name: 'Dosa Corner',
    cuisine: 'South Indian',
    rating: 4.7,
    emoji: '🥞',
    menu: [
      FoodItem(name: 'Masala Dosa', description: 'Crispy dosa with potato masala, chutney and sambar.', price: 99, emoji: '🥞'),
      FoodItem(name: 'Idli Sambar', description: 'Steamed idlis with hot sambar and chutney.', price: 79, emoji: '🍚'),
      FoodItem(name: 'Vada', description: 'Crispy lentil fritters with chutney.', price: 69, emoji: '🧆'),
    ],
  ),
];

class CartLine {
  final FoodItem item;
  int quantity;
  CartLine(this.item, this.quantity);
  double get total => item.price * quantity;
}

class FoodieGoApp extends StatefulWidget {
  const FoodieGoApp({super.key});

  @override
  State<FoodieGoApp> createState() => _FoodieGoAppState();
}

class _FoodieGoAppState extends State<FoodieGoApp> {
  int tab = 0;
  final List<CartLine> cart = [];
  final List<String> orders = [];
  late final Razorpay razorpay;

  // Replace this with your Razorpay TEST key from the Razorpay Dashboard.
  // Never put the Razorpay key_secret inside the app.
  static const razorpayKey = 'rzp_test_REPLACE_ME';

  @override
  void initState() {
    super.initState();
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _paymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _paymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _externalWallet);
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  double get cartTotal => cart.fold(0, (sum, line) => sum + line.total);

  void addToCart(FoodItem item) {
    setState(() {
      final existing = cart.where((line) => line.item.name == item.name).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        cart.add(CartLine(item, 1));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart')),
    );
  }

  void changeQuantity(CartLine line, int delta) {
    setState(() {
      line.quantity += delta;
      if (line.quantity <= 0) cart.remove(line);
    });
  }

  void startPayment() {
    if (cart.isEmpty) return;
    if (razorpayKey.contains('REPLACE_ME')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your Razorpay TEST key in lib/main.dart first.')),
      );
      return;
    }
    final options = {
      'key': razorpayKey,
      'amount': ((cartTotal + 30) * 100).round(),
      'name': 'Foodie Go',
      'description': 'Food order payment',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#FF6B35'},
    };
    try {
      razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open payment: $e')),
      );
    }
  }

  void _paymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      orders.insert(0, 'Order #${response.paymentId ?? 'PAID'} • ₹${cartTotal.toStringAsFixed(0)}');
      cart.clear();
      tab = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful. Order placed!')),
    );
  }

  void _paymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message ?? 'Try again'}')),
    );
  }

  void _externalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName ?? 'Wallet'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foodie Go',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFBF8),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Foodie Go', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: () => setState(() => tab = 1),
              icon: Badge(label: Text('${cart.length}'), isLabelVisible: cart.isNotEmpty, child: const Icon(Icons.shopping_cart_outlined)),
            ),
          ],
        ),
        body: IndexedStack(
          index: tab,
          children: [
            _home(),
            _cart(),
            _orders(),
            _profile(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (index) => setState(() => tab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Cart'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _home() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hungry?', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Delicious food delivered to your door.', style: TextStyle(color: Colors.white, fontSize: 16)),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search food or restaurants',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _Category(icon: '🍛', name: 'Biryani'),
              _Category(icon: '🍔', name: 'Burgers'),
              _Category(icon: '🍕', name: 'Pizza'),
              _Category(icon: '🥞', name: 'South Indian'),
              _Category(icon: '🍰', name: 'Desserts'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Popular Restaurants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...restaurants.map((restaurant) => _restaurantCard(restaurant)),
      ],
    );
  }

  Widget _restaurantCard(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(radius: 28, child: Text(restaurant.emoji, style: const TextStyle(fontSize: 28))),
        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${restaurant.cuisine}\n⭐ ${restaurant.rating} • 25-35 min'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MenuPage(restaurant: restaurant, onAdd: addToCart))),
      ),
    );
  }

  Widget _cart() {
    if (cart.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, size: 72), SizedBox(height: 12), Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Your Cart', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...cart.map((line) => Card(child: ListTile(
          leading: Text(line.item.emoji, style: const TextStyle(fontSize: 30)),
          title: Text(line.item.name),
          subtitle: Text('₹${line.item.price.toStringAsFixed(0)} × ${line.quantity}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: () => changeQuantity(line, -1), icon: const Icon(Icons.remove_circle_outline)),
            Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => changeQuantity(line, 1), icon: const Icon(Icons.add_circle_outline)),
          ]),
        ))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _summaryRow('Subtotal', cartTotal),
          _summaryRow('Delivery', 30),
          const Divider(),
          _summaryRow('Total', cartTotal + 30, bold: true),
        ]))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: startPayment, icon: const Icon(Icons.payment), label: const Text('Pay with Razorpay')),
      ],
    );
  }

  Widget _summaryRow(String title, double amount, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 15);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: style), Text('₹${amount.toStringAsFixed(0)}', style: style)]));
  }

  Widget _orders() {
    if (orders.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_outlined, size: 72), SizedBox(height: 12), Text('No orders yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]));
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('My Orders', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...orders.map((order) => Card(child: ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(order), subtitle: const Text('Confirmed • Preparing'))),
    ]);
  }

  Widget _profile() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)),
      const SizedBox(height: 12),
      const Center(child: Text('Foodie Go User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      const SizedBox(height: 24),
      Card(child: Column(children: const [
        ListTile(leading: Icon(Icons.location_on_outlined), title: Text('Saved Address'), subtitle: Text('Add your delivery address')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.support_agent), title: Text('Help & Support'), subtitle: Text('Get help with your order')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.info_outline), title: Text('About Foodie Go'), subtitle: Text('Version 1.0.0')),
      ])),
    ]);
  }
}

class MenuPage extends StatelessWidget {
  final Restaurant restaurant;
  final ValueChanged<FoodItem> onAdd;
  const MenuPage({super.key, required this.restaurant, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(restaurant.cuisine, style: const TextStyle(color: Colors.black54)),
        Text('⭐ ${restaurant.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...restaurant.menu.map((item) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(radius: 30, child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${item.description}\n₹${item.price.toStringAsFixed(0)}'),
          isThreeLine: true,
          trailing: FilledButton(onPressed: () => onAdd(item), child: const Text('Add')),
        ))),
      ]),
    );
  }
}

class _Category extends StatelessWidget {
  final String icon;
  final String name;
  const _Category({required this.icon, required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(width: 82, margin: const EdgeInsets.only(right: 10), child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 30)), const SizedBox(height: 4), Text(name, overflow: TextOverflow.ellipsis)])));
  }
}
