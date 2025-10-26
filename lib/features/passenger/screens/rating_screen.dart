import 'package:flutter/material.dart';
import '../../../data/models/ticket_model.dart';

class RatingScreen extends StatefulWidget {
  final Booking booking;
  final bool isRatingDriver; // true para calificar conductor, false para calificar como pasajero
  final Function(int rating, String comment, List<String> tags)? onRatingSubmitted;

  const RatingScreen({
    Key? key,
    required this.booking,
    this.isRatingDriver = true,
    this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> _driverTags = [
    'Puntual',
    'Conducción segura',
    'Amable',
    'Profesional',
    'Vehículo limpio',
    'Buena comunicación',
    'Respetuoso',
    'Conoce la ruta',
  ];

  final List<String> _passengerTags = [
    'Puntual',
    'Respetuoso',
    'Silencioso',
    'Ordenado',
    'Amable',
    'Siguió las reglas',
    'Sin problemas',
    'Recomendado',
  ];

  @override
  Widget build(BuildContext context) {
    final tags = widget.isRatingDriver ? _driverTags : _passengerTags;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRatingDriver ? 'Calificar Conductor' : 'Calificar Viaje'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripInfo(),
            const SizedBox(height: 24),
            _buildRatingSection(),
            const SizedBox(height: 24),
            _buildTagsSection(tags),
            const SizedBox(height: 24),
            _buildCommentSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.indigo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.ticket.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.booking.ticket.origin} → ${widget.booking.ticket.destination}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Viaje completado el ${_formatDate(widget.booking.ticket.departureTime)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRatingDriver 
                  ? '¿Cómo fue tu experiencia con el conductor?'
                  : '¿Cómo calificarías este viaje?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: index < _rating ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingText(_rating),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRatingDriver 
                  ? '¿Qué destacarías del conductor?'
                  : '¿Qué destacarías del viaje?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selecciona las opciones que apliquen:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.indigo.shade100,
                  checkmarkColor: Colors.indigo,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comentarios adicionales (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.isRatingDriver 
                    ? 'Cuéntanos más sobre tu experiencia con el conductor...'
                    : 'Cuéntanos más sobre tu experiencia en este viaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _rating > 0 ? _submitRating : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Enviar Calificación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return 'Selecciona una calificación';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _submitRating() {
    // Llamar al callback si está disponible
    if (widget.onRatingSubmitted != null) {
      widget.onRatingSubmitted!(_rating, _commentController.text, _selectedTags);
    }
    
    // Aquí se enviaría la calificación al backend
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Gracias por tu calificación!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calificación: $_rating estrellas'),
            if (_selectedTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Aspectos destacados: ${_selectedTags.join(', ')}'),
            ],
            if (_commentController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Comentario: ${_commentController.text}'),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Volver con resultado
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}