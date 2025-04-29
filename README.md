# 🔤 Girimático

![Banner do Girimático](https://github.com/user-attachments/assets/e8193491-580f-4682-af91-2fd108bba57f)

## 📱 Visão Geral

**Autor:** Antony Henrique Bresolin

O **Girimático** é um aplicativo mobile desenvolvido para traduzir gírias brasileiras para o português formal. Este app permite que usuários digitem ou falem uma gíria, e utilizando processamento de linguagem natural, traduz a expressão para o português padrão, explicando seu significado.

## 🖼️ Screenshots e Demonstração

<p align="center">
  <img src="https://github.com/user-attachments/assets/0a1e2f32-f691-4acb-8487-209305da7959" width="250" alt="Tela inicial"/>
  <img src="https://github.com/user-attachments/assets/5a7af34a-afe5-4693-b853-9fe80b52df4a" width="250" alt="Resultado da tradução"/>
  <img src="https://github.com/user-attachments/assets/03e806ba-8f19-4af7-8d64-567ed0680984" width="250" alt="Filtros de região"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/5f1df2a8-3fdb-4de9-9771-51337858b07d" width="250" alt="Histórico de traduções"/>
  <img src="https://github.com/user-attachments/assets/be63f8eb-18c9-4c94-ab57-21e8ecee37e8" width="250" alt="Favoritos"/>
  <img src="https://github.com/user-attachments/assets/2cef76ab-41b5-4b3a-a4fb-b371747c3643" width="250" alt="Dicionário de gírias"/>
</p>

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework para desenvolvimento de aplicativos multiplataforma
- **Dart**: Linguagem de programação
- **API Gemini (Google AI)**: Para o processamento de linguagem natural e tradução das gírias
- **Pacotes principais**:
  - `http: ^1.3.0`: Para fazer requisições HTTP à API
  - `speech_to_text: ^7.0.0`: Para reconhecimento de voz
  - `share_plus: ^10.1.4`: Para compartilhamento de traduções
  - `animated_text_kit: ^4.2.3`: Para animações de texto
  - `flutter_dotenv: ^5.1.0`: Para gerenciamento de variáveis de ambiente
  - `cupertino_icons: ^1.0.8`: Para ícones no estilo iOS

## 🚀 Instalação e Execução

### Pré-requisitos

- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK (versão 2.17.0 ou superior)
- Chave de API do Google AI (Gemini)
- Android Studio ou VS Code

### Passo a passo

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/girimático.git
   cd girimático
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure as variáveis de ambiente**
   - Crie um arquivo `.env` na raiz do projeto
   - Adicione sua chave de API do Google AI:
     ```
     API_KEY=sua_chave_api_aqui
     ```

4. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 🧠 Uso de LLM no Projeto

O Girimático utiliza a API Gemini do Google AI para interpretar e traduzir gírias brasileiras. O modelo de linguagem é empregado das seguintes formas:

1. **Interpretação contextual**: O LLM analisa o contexto da gíria para fornecer traduções precisas.

2. **Adaptação regional**: O aplicativo permite filtrar traduções por regiões específicas do Brasil (Nordeste, Sul, Sudeste, etc.). O prompt enviado ao LLM é ajustado conforme a região selecionada.

3. **Personalização do estilo de resposta**: As traduções podem ser personalizadas em diferentes estilos (detalhado, conciso, didático, técnico, com exemplos) e níveis de formalidade (formal, normal, coloquial).

4. **Prompt Engineering**: O aplicativo utiliza prompts elaborados para instruir o modelo a fornecer traduções precisas e contextualmente relevantes:

```dart
final String prompt = '''
  Traduza a seguinte expressão ou gíria brasileira para $formalityLevel: "$textToTranslate"
  
  ${regionFocus.isNotEmpty ? 'Se possível, considere o contexto regional de: $regionFocus' : 'Identifique de qual região do Brasil esta gíria provavelmente vem, se for possível determinar.'}
  
  Apresente a tradução de $stylePrompt.
  
  Responda apenas com a tradução direta, sem introduções como "A tradução é..." ou "Isso significa...".
'''
```

Este método garante que o LLM forneça respostas estruturadas e adequadas ao contexto regional e estilístico selecionado pelo usuário.

## 📋 Funcionalidades

- Tradução de gírias brasileiras para português formal
- Reconhecimento de voz para entrada de gírias
- Filtros por região do Brasil
- Personalização do estilo de tradução
- Ajuste do nível de formalidade
- Histórico de traduções
- Sistema de favoritos
- Compartilhamento de traduções
- Dicionário de gírias comuns

## 📝 Licença

Este projeto está sob a licença MIT.

---

Desenvolvido com 💙 por Antony Henrique Bresolin
