import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Girimático',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B7BF5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B7BF5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      themeMode: ThemeMode.system,
      home: const TranslatorScreen(),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({Key? key}) : super(key: key);

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  String _originalText = '';
  bool _isLoading = false;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _selectedRegionFilter = 'Todas';
  String _selectedStyleFilter = 'Detalhado';
  String _selectedFormality = 'Normal';
  bool _showFavorites = false;
  List<TranslationEntry> _favoriteTranslations = [];
  List<TranslationEntry> _translationHistory = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _regionFilters = [
    'Todas',
    'Nordeste',
    'Sul',
    'Sudeste',
    'Norte',
    'Centro-Oeste',
    'Internet',
  ];
  final List<String> _styleFilters = [
    'Detalhado',
    'Conciso',
    'Com exemplos',
    'Didático',
    'Técnico',
  ];
  final List<String> _formalityLevels = ['Formal', 'Normal', 'Coloquial'];

  final List<GiriaExample> _giriaExamples = [
    GiriaExample('Bora desenrolar esse papo', 'Internet/Jovem'),
    GiriaExample('Tá me tirando?', 'Geral'),
    GiriaExample('Pegar o beco', 'Nordeste'),
    GiriaExample('Esse cara é mó gente boa', 'Sudeste'),
    GiriaExample('Bah, tchê, que tri!', 'Sul'),
    GiriaExample('Tô liso', 'Geral'),
    GiriaExample('Partiu rolê', 'Jovem'),
    GiriaExample('Dar um perdido', 'Nordeste'),
    GiriaExample('Botar pilha', 'Geral'),
    GiriaExample('Mano do céu', 'Sudeste'),
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _loadSavedTranslations();
  }

  void _loadSavedTranslations() {
    _favoriteTranslations = [
      TranslationEntry(
        originalText: 'O cara meteu o pé na jaca ontem na festa',
        translatedText:
            'A pessoa exagerou no comportamento ou no consumo de bebidas durante a festa de ontem.',
        region: 'Sudeste',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TranslationEntry(
        originalText: 'Aquela parada tá osso de resolver',
        translatedText: 'Aquela situação está difícil de ser solucionada.',
        region: 'Geral',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    _translationHistory = [
      TranslationEntry(
        originalText: 'Vou nessa que o bicho vai pegar',
        translatedText:
            'Vou embora porque a situação vai ficar complicada ou tensa.',
        region: 'Geral',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TranslationEntry(
        originalText: 'Deu ruim pra ele',
        translatedText: 'Ocorreu algo negativo para essa pessoa.',
        region: 'Internet',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TranslationEntry(
        originalText: 'A firma tá estourada de trampo',
        translatedText: 'A empresa está com muito trabalho acumulado.',
        region: 'Sudeste',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (errorNotification) {
        setState(() {
          _isListening = false;
        });
      },
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
          localeId: 'pt_BR',
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  Future<void> _translateText() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Digite ou fale alguma gíria para traduzir');
      return;
    }

    setState(() {
      _isLoading = true;
      _originalText = _textController.text;
    });

    try {
      final String apiKey = dotenv.env['API_KEY'] ?? '';
      final String apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

      final String textToTranslate = _textController.text;

      String regionFocus =
          _selectedRegionFilter != 'Todas' ? _selectedRegionFilter : '';
      String stylePrompt = '';

      switch (_selectedStyleFilter) {
        case 'Conciso':
          stylePrompt = 'forma concisa e direta';
          break;
        case 'Com exemplos':
          stylePrompt = 'incluindo exemplos de uso no português formal';
          break;
        case 'Didático':
          stylePrompt = 'explicando de forma didática a origem e significado';
          break;
        case 'Técnico':
          stylePrompt =
              'utilizando terminologia técnica da linguística quando relevante';
          break;
        default:
          stylePrompt = 'forma detalhada, explicando o contexto';
      }

      String formalityLevel = '';
      switch (_selectedFormality) {
        case 'Formal':
          formalityLevel = 'português formal e culto';
          break;
        case 'Coloquial':
          formalityLevel = 'português padrão mas com linguagem mais relaxada';
          break;
        default:
          formalityLevel = 'português padrão com nível moderado de formalidade';
      }

      final String prompt = '''
        Traduza a seguinte expressão ou gíria brasileira para $formalityLevel: "$textToTranslate"
        
        ${regionFocus.isNotEmpty ? 'Se possível, considere o contexto regional de: $regionFocus' : 'Identifique de qual região do Brasil esta gíria provavelmente vem, se for possível determinar.'}
        
        Apresente a tradução de $stylePrompt.
        
        Responda apenas com a tradução direta, sem introduções como "A tradução é..." ou "Isso significa...".
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 800,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String content =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _translatedText = content;

          if (_translationHistory.length >= 10) {
            _translationHistory.removeLast();
          }
          _translationHistory.insert(
            0,
            TranslationEntry(
              originalText: _originalText,
              translatedText: content,
              region:
                  _selectedRegionFilter != 'Todas'
                      ? _selectedRegionFilter
                      : 'Não especificada',
              timestamp: DateTime.now(),
            ),
          );
        });

        _animationController.reset();
        _animationController.forward();
      } else {
        _showSnackBar('Erro ao traduzir. Tente novamente.');
      }
    } catch (e) {
      _showSnackBar('Erro ao conectar com a API. Verifique sua conexão.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() {
    if (_translatedText.isEmpty) return;

    final newEntry = TranslationEntry(
      originalText: _originalText,
      translatedText: _translatedText,
      region:
          _selectedRegionFilter != 'Todas'
              ? _selectedRegionFilter
              : 'Não especificada',
      timestamp: DateTime.now(),
    );

    setState(() {
      final existingIndex = _favoriteTranslations.indexWhere(
        (item) => item.originalText == _originalText,
      );

      if (existingIndex >= 0) {
        _favoriteTranslations.removeAt(existingIndex);
        _showSnackBar('Tradução removida dos favoritos');
      } else {
        _favoriteTranslations.add(newEntry);
        _showSnackBar('Tradução adicionada aos favoritos');
      }
    });
  }

  void _shareTranslation() {
    if (_translatedText.isEmpty) return;

    Share.share(
      '📚 Tradução do Girimático 📚\n\nGíria: $_originalText\n\nSignificado: $_translatedText\n\nCompartilhado do app Girimático - Tradutor de Gírias',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personalizar Tradução',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    const Text(
                      'Região:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children:
                          _regionFilters.map((region) {
                            return FilterChip(
                              label: Text(region),
                              selected: _selectedRegionFilter == region,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedRegionFilter =
                                      selected ? region : 'Todas';
                                });
                                setState(() {
                                  _selectedRegionFilter =
                                      selected ? region : 'Todas';
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Estilo da tradução:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children:
                          _styleFilters.map((style) {
                            return FilterChip(
                              label: Text(style),
                              selected: _selectedStyleFilter == style,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedStyleFilter =
                                      selected ? style : 'Detalhado';
                                });
                                setState(() {
                                  _selectedStyleFilter =
                                      selected ? style : 'Detalhado';
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Nível de formalidade:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children:
                          _formalityLevels.map((level) {
                            return FilterChip(
                              label: Text(level),
                              selected: _selectedFormality == level,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedFormality =
                                      selected ? level : 'Normal';
                                });
                                setState(() {
                                  _selectedFormality =
                                      selected ? level : 'Normal';
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Aplicar Filtros'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              List<TranslationEntry> displayEntries =
                  _showFavorites ? _favoriteTranslations : _translationHistory;

              return Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _showFavorites
                              ? 'Traduções Favoritas'
                              : 'Histórico de Traduções',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _showFavorites ? Icons.history : Icons.favorite,
                                color: _showFavorites ? null : Colors.red,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  _showFavorites = !_showFavorites;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),

                    displayEntries.isEmpty
                        ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showFavorites
                                      ? Icons.favorite_border
                                      : Icons.history_toggle_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _showFavorites
                                      ? 'Nenhuma tradução favorita ainda'
                                      : 'Seu histórico está vazio',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: displayEntries.length,
                            itemBuilder: (context, index) {
                              final entry = displayEntries[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _textController.text = entry.originalText;
                                      _originalText = entry.originalText;
                                      _translatedText = entry.translatedText;
                                    });
                                    Navigator.pop(context);

                                    _animationController.reset();
                                    _animationController.forward();
                                  },
                                  child: ExpansionTile(
                                    title: Text(
                                      entry.originalText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Região: ${entry.region} • ${_formatDate(entry.timestamp)}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Tradução:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(entry.translatedText),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.content_copy,
                                                  ),
                                                  onPressed: () {
                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text:
                                                            "Gíria: ${entry.originalText}\n\nSignificado: ${entry.translatedText}",
                                                      ),
                                                    );
                                                    _showSnackBar(
                                                      'Tradução copiada para a área de transferência',
                                                    );
                                                    Navigator.pop(context);
                                                  },
                                                  tooltip: 'Copiar',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    _showFavorites
                                                        ? Icons.delete_outline
                                                        : Icons.favorite,
                                                    color:
                                                        _showFavorites
                                                            ? null
                                                            : Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    if (_showFavorites) {
                                                      setModalState(() {
                                                        _favoriteTranslations
                                                            .removeAt(index);
                                                      });
                                                      setState(() {
                                                        _favoriteTranslations
                                                            .removeAt(index);
                                                      });
                                                    } else {
                                                      final existingIndex =
                                                          _favoriteTranslations
                                                              .indexWhere(
                                                                (item) =>
                                                                    item.originalText ==
                                                                    entry
                                                                        .originalText,
                                                              );

                                                      if (existingIndex >= 0) {
                                                        _showSnackBar(
                                                          'Esta tradução já está nos favoritos',
                                                        );
                                                      } else {
                                                        setModalState(() {
                                                          _favoriteTranslations
                                                              .add(entry);
                                                        });
                                                        setState(() {
                                                          _favoriteTranslations
                                                              .add(entry);
                                                        });
                                                        _showSnackBar(
                                                          'Adicionado aos favoritos',
                                                        );
                                                      }
                                                    }
                                                  },
                                                  tooltip:
                                                      _showFavorites
                                                          ? 'Remover dos favoritos'
                                                          : 'Adicionar aos favoritos',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.share),
                                                  onPressed: () {
                                                    Share.share(
                                                      '📚 Tradução do Girimático 📚\n\nGíria: ${entry.originalText}\n\nSignificado: ${entry.translatedText}\n\nCompartilhado do app Girimático - Tradutor de Gírias',
                                                    );
                                                  },
                                                  tooltip: 'Compartilhar',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showDictionaryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dicionário de Gírias',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Pesquisar gírias...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: 20,
                        itemBuilder: (context, index) {
                          List<String> girias = [
                            'Arretado',
                            'Barca',
                            'Caraca',
                            'Da hora',
                            'Esperto',
                            'Fechamento',
                            'Grilado',
                            'Irado',
                            'Jóia',
                            'Liso',
                            'Mano',
                            'Novinha',
                            'Osso',
                            'Paia',
                            'Quebrada',
                            'Rolê',
                            'Sangue Bom',
                            'Treta',
                            'Vibe',
                            'Zuar',
                          ];

                          List<String> regioes = [
                            'Nordeste',
                            'Sudeste',
                            'Sudeste',
                            'Sudeste',
                            'Geral',
                            'Sudeste',
                            'Geral',
                            'Sudeste',
                            'Geral',
                            'Nordeste',
                            'Sudeste',
                            'Geral',
                            'Geral',
                            'Centro-Oeste',
                            'Sudeste',
                            'Geral',
                            'Sudeste',
                            'Geral',
                            'Internet',
                            'Sudeste',
                          ];

                          if (index >= girias.length) return null;

                          return Card(
                            child: ListTile(
                              title: Text(
                                girias[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Região: ${regioes[index]}'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                _textController.text = girias[index];
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool isInFavorites = _favoriteTranslations.any(
      (entry) =>
          entry.originalText == _originalText && _originalText.isNotEmpty,
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              title: const Text('Girimático'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Filtros',
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: _showHistoryBottomSheet,
                  tooltip: 'Histórico',
                ),
                IconButton(
                  icon: const Icon(Icons.book),
                  onPressed: _showDictionaryBottomSheet,
                  tooltip: 'Dicionário',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 70.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.translate,
                            color: Colors.white,
                            size: 28,
                          ),
                          Text(
                            'Tradutor de Gírias',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Digite ou fale a gíria:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    decoration: InputDecoration(
                                      hintText: 'Ex: "Tô chapado de sono"',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                    maxLines: 2,
                                    minLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor:
                                      _isListening
                                          ? Colors.red.shade200
                                          : colorScheme.secondaryContainer,
                                  child: IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color:
                                          _isListening
                                              ? Colors.red
                                              : colorScheme
                                                  .onSecondaryContainer,
                                    ),
                                    onPressed: _listen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _translateText,
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text('TRADUZIR'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 8,
                      children: [
                        if (_selectedRegionFilter != 'Todas')
                          Chip(
                            label: Text('Região: $_selectedRegionFilter'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedRegionFilter = 'Todas';
                              });
                            },
                          ),
                        if (_selectedStyleFilter != 'Detalhado')
                          Chip(
                            label: Text('Estilo: $_selectedStyleFilter'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedStyleFilter = 'Detalhado';
                              });
                            },
                          ),
                        if (_selectedFormality != 'Normal')
                          Chip(
                            label: Text('Formalidade: $_selectedFormality'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedFormality = 'Normal';
                              });
                            },
                          ),
                      ],
                    ),

                    if (_translatedText.isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Exemplos de gírias:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _giriaExamples.map((example) {
                                  return ActionChip(
                                    label: Text(example.text),
                                    avatar: const Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                    ),
                                    tooltip: example.region,
                                    onPressed: () {
                                      setState(() {
                                        _textController.text = example.text;
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),

                    if (_translatedText.isNotEmpty)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: BorderSide(
                              color: colorScheme.primaryContainer,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          margin: const EdgeInsets.only(top: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'GÍRIA',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _originalText,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'TRADUÇÃO',
                                        style: TextStyle(
                                          color: colorScheme.onTertiary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _translatedText,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isInFavorites
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            isInFavorites ? Colors.red : null,
                                      ),
                                      onPressed: _toggleFavorite,
                                      tooltip:
                                          isInFavorites
                                              ? 'Remover dos favoritos'
                                              : 'Adicionar aos favoritos',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.content_copy),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text:
                                                "Gíria: $_originalText\n\nSignificado: $_translatedText",
                                          ),
                                        );
                                        _showSnackBar(
                                          'Tradução copiada para a área de transferência',
                                        );
                                      },
                                      tooltip: 'Copiar tradução',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: _shareTranslation,
                                      tooltip: 'Compartilhar',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: colorScheme.surface,
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Conheça as gírias de todo o Brasil!',
              textStyle: TextStyle(fontSize: 14, color: colorScheme.primary),
              speed: const Duration(milliseconds: 100),
            ),
            TypewriterAnimatedText(
              'Filtros regionais disponíveis!',
              textStyle: TextStyle(fontSize: 14, color: colorScheme.primary),
              speed: const Duration(milliseconds: 100),
            ),
            TypewriterAnimatedText(
              'Compartilhe traduções com amigos!',
              textStyle: TextStyle(fontSize: 14, color: colorScheme.primary),
              speed: const Duration(milliseconds: 100),
            ),
          ],
          totalRepeatCount: 100,
          pause: const Duration(milliseconds: 3000),
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class TranslationEntry {
  final String originalText;
  final String translatedText;
  final String region;
  final DateTime timestamp;

  TranslationEntry({
    required this.originalText,
    required this.translatedText,
    required this.region,
    required this.timestamp,
  });
}

class GiriaExample {
  final String text;
  final String region;

  GiriaExample(this.text, this.region);
}
