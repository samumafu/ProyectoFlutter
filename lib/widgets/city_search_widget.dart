import 'package:flutter/material.dart';
import '../services/city_search_service.dart';

class CitySearchWidget extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(Map<String, dynamic>) onCitySelected;
  final List<String> recentSearches;

  const CitySearchWidget({
    Key? key,
    required this.label,
    this.initialValue,
    required this.onCitySelected,
    this.recentSearches = const [],
  }) : super(key: key);

  @override
  State<CitySearchWidget> createState() => _CitySearchWidgetState();
}

class _CitySearchWidgetState extends State<CitySearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _suggestions = CitySearchService.getSuggestionsForUser(widget.recentSearches);
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showSuggestionsOverlay();
      } else {
        _hideSuggestionsOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideSuggestionsOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSuggestionsOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }

  void _hideSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showSuggestions = false);
  }

  void _onSearchChanged(String query) {
    final results = CitySearchService.searchCities(query);
    setState(() {
      _suggestions = results;
    });
    _updateOverlay();
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _selectCity(Map<String, dynamic> city) {
    _controller.text = city['name'];
    _hideSuggestionsOverlay();
    _focusNode.unfocus();
    widget.onCitySelected(city);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                    },
                  )
                : const Icon(Icons.location_city),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            hintText: 'Buscar ciudad o municipio...',
          ),
          onChanged: _onSearchChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No se encontraron ciudades',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final city = _suggestions[index];
        return _buildSuggestionItem(city);
      },
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> city) {
    final isRecent = city['isRecent'] == true;
    final isLocal = city['isLocal'] == true;
    
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isLocal ? Colors.indigo.shade100 : Colors.blue.shade100,
        child: Icon(
          isRecent 
              ? Icons.history 
              : isLocal 
                  ? Icons.location_city 
                  : Icons.location_on,
          size: 16,
          color: isLocal ? Colors.indigo : Colors.blue,
        ),
      ),
      title: Text(
        city['name'],
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              city['region'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          if (isRecent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reciente',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (isLocal && !isRecent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Nariño',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (city['type'] == 'capital')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Capital',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _selectCity(city),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.grey,
      ),
    );
  }
}