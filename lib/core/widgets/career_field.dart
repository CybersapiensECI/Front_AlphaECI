import 'package:flutter/material.dart';

import '../constants/careers.dart';

/// Campo de carrera de escritura libre con autocompletado.
///
/// El usuario escribe ("sistemas", "civil"…) y se le sugieren las carreras
/// del catálogo; el valor que viaja al backend sigue siendo el código del
/// enum (profile-service NO acepta texto libre, ver careers.dart), así que
/// el validator exige que lo escrito resuelva a una carrera conocida.
class CareerField extends StatefulWidget {
  const CareerField({
    super.key,
    this.initialCode,
    required this.onChanged,
    this.required = true,
  });

  /// Código inicial (p. ej. 'SYSTEMS_ENGINEERING') o null.
  final String? initialCode;

  /// Notifica el código resuelto, o null mientras lo escrito no corresponda
  /// a ninguna carrera del catálogo.
  final ValueChanged<String?> onChanged;

  /// false: permite dejarlo vacío (p. ej. editar perfil, donde vacío
  /// significa "no cambiar la carrera").
  final bool required;

  @override
  State<CareerField> createState() => _CareerFieldState();
}

class _CareerFieldState extends State<CareerField> {
  /// Sin tildes y en minúsculas, para que "ingenieria" encuentre "Ingeniería".
  static String _normalize(String s) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    var out = s.toLowerCase().trim();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i].toLowerCase());
    }
    return out;
  }

  static String? _codeForText(String text) {
    final query = _normalize(text);
    if (query.isEmpty) return null;
    for (final entry in careerLabels.entries) {
      if (_normalize(entry.value) == query) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(
        text: widget.initialCode == null
            ? ''
            : careerLabel(widget.initialCode!),
      ),
      optionsBuilder: (value) {
        final query = _normalize(value.text);
        if (query.isEmpty) return careerLabels.values;
        return careerLabels.values
            .where((label) => _normalize(label).contains(query));
      },
      onSelected: (label) => widget.onChanged(_codeForText(label)),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Carrera',
            hintText: 'Escribe tu carrera…',
            suffixIcon: Icon(Icons.school_outlined),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (text) => widget.onChanged(_codeForText(text)),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return widget.required ? 'Escribe tu carrera.' : null;
            }
            if (_codeForText(value) == null) {
              return 'Elige una carrera de las sugerencias.';
            }
            return null;
          },
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        // Panel propio para poder acotar el ancho y alto en pantallas chicas.
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final label = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(label),
                    onTap: () => onSelected(label),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
