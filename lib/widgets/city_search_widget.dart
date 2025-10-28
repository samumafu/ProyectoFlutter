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

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _loadSuggestions();
        setState(() => _showSuggestions = true);
      } else {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    final query = _controller.text;
    List<Map<String, dynamic>> results;
    
    if (query.isEmpty) {
      results = CitySearchService.getSuggestionsForUser(widget.recentSearches);
    } else {
      results = CitySearchService.searchCities(query);
    }
    
    setState(() {
      _suggestions = results;
    });
  }

  void _selectCity(Map<String, dynamic> city) {
    print('Selecting city: ${city['name']}');
    
    setState(() {
      _controller.text = city['name'];
      _showSuggestions = false;
    });
    
    _focusNode.unfocus();
    
    // Ejecutar callback
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
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            _loadSuggestions();
          },
          onTap: () {
            _loadSuggestions();
            setState(() => _showSuggestions = true);
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final city = _suggestions[index];
                final isRecent = city['isRecent'] == true;
                final isLocal = city['isLocal'] == true;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      print('City tapped: ${city['name']}');
                      _selectCity(city);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}