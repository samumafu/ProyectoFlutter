import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> faqItems = [
    {
      'question': '¿Cómo puedo reservar un asiento?',
      'answer': 'Puedes reservar un asiento buscando tu ruta deseada, seleccionando el viaje y eligiendo tus asientos preferidos en el mapa de asientos.',
      'isExpanded': false,
    },
    {
      'question': '¿Puedo cancelar mi reserva?',
      'answer': 'Sí, puedes cancelar tu reserva hasta 2 horas antes de la salida del viaje. Ve a tu historial de viajes y selecciona la opción de cancelar.',
      'isExpanded': false,
    },
    {
      'question': '¿Qué métodos de pago aceptan?',
      'answer': 'Actualmente aceptamos efectivo. Próximamente integraremos Nequi, DaviPlata y tarjetas de crédito/débito.',
      'isExpanded': false,
    },
    {
      'question': '¿Cómo puedo contactar al conductor?',
      'answer': 'Una vez confirmada tu reserva, podrás chatear directamente con el conductor desde la pantalla de detalles del viaje.',
      'isExpanded': false,
    },
    {
      'question': '¿Qué pasa si pierdo mi viaje?',
      'answer': 'Si pierdes tu viaje, contacta inmediatamente al soporte. Dependiendo de las circunstancias, podremos ayudarte a reprogramar tu viaje.',
      'isExpanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Soporte'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner del chatbot IA (próximamente)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Asistente IA - Próximamente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pronto tendrás un asistente inteligente que te ayudará 24/7 con todas tus consultas sobre viajes.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showComingSoonDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple.shade600,
                    ),
                    child: const Text('Conocer más'),
                  ),
                ],
              ),
            ),
            
            // Opciones de contacto rápido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickContactCard(
                      icon: Icons.phone,
                      title: 'Llamar',
                      subtitle: 'Soporte telefónico',
                      color: Colors.green,
                      onTap: () => _showContactInfo('phone'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickContactCard(
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: 'Enviar consulta',
                      color: Colors.blue,
                      onTap: () => _showContactInfo('email'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickContactCard(
                      icon: Icons.chat,
                      title: 'Chat',
                      subtitle: 'Chat en vivo',
                      color: Colors.orange,
                      onTap: () => _showComingSoonDialog(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Preguntas frecuentes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preguntas Frecuentes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionPanelList(
                    elevation: 1,
                    expandedHeaderPadding: EdgeInsets.zero,
                    children: faqItems.asMap().entries.map<ExpansionPanel>((entry) {
                      int index = entry.key;
                      Map<String, dynamic> item = entry.value;
                      
                      return ExpansionPanel(
                        headerBuilder: (context, isExpanded) {
                          return ListTile(
                            title: Text(
                              item['question'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            item['answer'],
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                        isExpanded: item['isExpanded'],
                      );
                    }).toList(),
                    expansionCallback: (panelIndex, isExpanded) {
                      setState(() {
                        faqItems[panelIndex]['isExpanded'] = !isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Información adicional
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de Contacto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        Icons.location_on,
                        'Dirección',
                        'Calle 18 #25-40, Pasto, Nariño',
                      ),
                      _buildContactItem(
                        Icons.access_time,
                        'Horario de Atención',
                        'Lunes a Domingo: 6:00 AM - 10:00 PM',
                      ),
                      _buildContactItem(
                        Icons.language,
                        'Sitio Web',
                        'www.busreserva.com',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Asistente IA'),
          ],
        ),
        content: const Text(
          'Estamos desarrollando un asistente de inteligencia artificial que te ayudará con:\n\n'
          '• Búsqueda inteligente de rutas\n'
          '• Recomendaciones personalizadas\n'
          '• Soporte 24/7\n'
          '• Resolución automática de consultas\n'
          '• Predicción de precios y horarios\n\n'
          'Esta funcionalidad estará disponible próximamente.',
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

  void _showContactInfo(String type) {
    String title = '';
    String content = '';
    
    switch (type) {
      case 'phone':
        title = 'Contacto Telefónico';
        content = 'Línea de atención al cliente:\n\n'
                 '📞 (602) 123-4567\n'
                 '📱 WhatsApp: +57 300 123 4567\n\n'
                 'Horario: Lunes a Domingo\n'
                 '6:00 AM - 10:00 PM';
        break;
      case 'email':
        title = 'Contacto por Email';
        content = 'Envía tu consulta a:\n\n'
                 '📧 soporte@busreserva.com\n'
                 '📧 info@busreserva.com\n\n'
                 'Tiempo de respuesta:\n'
                 'Máximo 24 horas hábiles';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}