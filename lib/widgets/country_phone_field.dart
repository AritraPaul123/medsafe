import 'package:flutter/material.dart';

class CountryPhoneField extends StatefulWidget {
  final String? initialFullNumber; // e.g. "+91 9876543210" or "9876543210"
  final String defaultDial; // used if initial has no +code
  final ValueChanged<String>?
      onChanged; // emits composed full number "+XX local"
  final TextEditingController?
      controller; // controller for the local part (optional)
  final String? Function(String? fullNumber)?
      validator; // validate composed number

  const CountryPhoneField({
    super.key,
    this.initialFullNumber,
    this.defaultDial = '+91',
    this.onChanged,
    this.controller,
    this.validator,
  });

  @override
  State<CountryPhoneField> createState() => _CountryPhoneFieldState();
}

class _CountryPhoneFieldState extends State<CountryPhoneField> {
  late TextEditingController _localCtrl;
  late String _dial;

  // minimal, extend any time
  static const _dialOptions = <String, String>{
    '🇮🇳 India': '+91',
    '🇺🇸 United States': '+1',
    '🇬🇧 United Kingdom': '+44',
    '🇦🇺 Australia': '+61',
    '🇨🇦 Canada': '+1',
    '🇦🇪 UAE': '+971',
    '🇸🇬 Singapore': '+65',
    '🇩🇪 Germany': '+49',
    '🇫🇷 France': '+33',
  };

  @override
  void initState() {
    super.initState();
    final parsed = _splitInitial(widget.initialFullNumber, widget.defaultDial);
    _dial = parsed.$1;
    _localCtrl = widget.controller ?? TextEditingController(text: parsed.$2);
    _localCtrl.addListener(_emit);
    // emit initial value once
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    if (widget.controller == null) _localCtrl.dispose();
    super.dispose();
  }

  // ---- helpers ----

  // returns (dial, local)
  (String, String) _splitInitial(String? input, String fallbackDial) {
    if (input == null || input.trim().isEmpty) return (fallbackDial, '');
    final s = input.trim();
    final m = RegExp(r'^\+(\d{1,3})\s*[- ]?\s*').firstMatch(s);
    if (m == null) return (fallbackDial, s);
    final dial = '+${m.group(1)!}';
    final local = s.replaceFirst(m.group(0)!, '').trim();
    return (dial, local);
  }

  String _compose(String dial, String local) {
    if (local.startsWith('+')) return local.trim(); // user pasted full number
    return '$dial ${local.trim()}'.trim();
  }

  void _emit() {
    final full = _compose(_dial, _localCtrl.text);
    widget.onChanged?.call(full);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: t.colorScheme.outline.withOpacity(0.4)),
    );

    return Row(
      children: [
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _dial,
            decoration: InputDecoration(
              labelText: 'Code',
              border: outline,
              enabledBorder: outline,
              focusedBorder: outline,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: _dialOptions.entries.map((e) {
              return DropdownMenuItem<String>(
                value: e.value,
                child: Text('${e.key}  ${e.value}',
                    overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _dial = v);
              _emit();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _localCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone',
              hintText: 'Phone number',
              border: outline,
              enabledBorder: outline,
              focusedBorder: outline,
            ),
            validator: (_) =>
                widget.validator?.call(_compose(_dial, _localCtrl.text)),
            onFieldSubmitted: (_) => _emit(),
          ),
        ),
      ],
    );
  }
}
