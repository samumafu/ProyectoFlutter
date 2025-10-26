import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': '1',
      'type': 'nequi',
      'name': 'Nequi',
      'description': 'Paga con tu celular',
      'icon': Icons.phone_android,
      'color': Colors.purple,
      'isActive': true,
      'isDefault': true,
    },
    {
      'id': '2',
      'type': 'daviplata',
      'name': 'DaviPlata',
      'description': 'Billetera digital del Banco Davivienda',
      'icon': Icons.account_balance_wallet,
      'color': Colors.red,
      'isActive': true,
      'isDefault': false,
    },
    {
      'id': '3',
      'type': 'cash',
      'name': 'Efectivo',
      'description': 'Pago en efectivo al conductor',
      'icon': Icons.money,
      'color': Colors.green,
      'isActive': true,
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPaymentMethodDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Próximamente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Estamos trabajando en la integración con Nequi y DaviPlata para ofrecerte más opciones de pago seguras y convenientes.',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          
          // Lista de métodos de pago
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                return _buildPaymentMethodCard(method, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: method['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            method['icon'],
            color: method['color'],
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Text(
              method['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (method['isDefault']) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Predeterminado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(method['description']),
            if (!method['isActive']) ...[
              const SizedBox(height: 4),
              Text(
                'No disponible temporalmente',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'set_default':
                _setAsDefault(index);
                break;
              case 'configure':
                _configurePaymentMethod(method);
                break;
              case 'remove':
                _removePaymentMethod(index);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!method['isDefault'])
              const PopupMenuItem(
                value: 'set_default',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Establecer como predeterminado'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'configure',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Configurar'),
                ],
              ),
            ),
            if (method['type'] != 'cash')
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
        onTap: method['isActive'] ? () => _selectPaymentMethod(method) : null,
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Método de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone_android, color: Colors.purple),
              title: const Text('Nequi'),
              subtitle: const Text('Próximamente disponible'),
              enabled: false,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog('Nequi');
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.red),
              title: const Text('DaviPlata'),
              subtitle: const Text('Próximamente disponible'),
              enabled: false,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog('DaviPlata');
              },
            ),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Tarjeta de Crédito/Débito'),
              subtitle: const Text('Próximamente disponible'),
              enabled: false,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog('Tarjetas');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String paymentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$paymentType - Próximamente'),
        content: Text(
          'Estamos trabajando en la integración con $paymentType. '
          'Esta funcionalidad estará disponible en una próxima actualización.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(int index) {
    setState(() {
      // Remover predeterminado de todos
      for (var method in paymentMethods) {
        method['isDefault'] = false;
      }
      // Establecer como predeterminado
      paymentMethods[index]['isDefault'] = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${paymentMethods[index]['name']} establecido como predeterminado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _configurePaymentMethod(Map<String, dynamic> method) {
    if (method['type'] == 'nequi' || method['type'] == 'daviplata') {
      _showComingSoonDialog(method['name']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración no disponible para este método'),
        ),
      );
    }
  }

  void _removePaymentMethod(int index) {
    final method = paymentMethods[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Método de Pago'),
        content: Text('¿Estás seguro de que quieres eliminar ${method['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                paymentMethods.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${method['name']} eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _selectPaymentMethod(Map<String, dynamic> method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method['name']} seleccionado para próximos pagos'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}