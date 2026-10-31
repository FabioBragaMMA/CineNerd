# CineNerd — Documentação Completa do Projeto

A **CineNerd** é uma aplicação móvel de catálogo, exploração e organização cinematográfica desenvolvida com a framework **Flutter** e a linguagem **Dart**. Este documento descreve de forma exaustiva todas as funcionalidades implementadas, a organização detalhada do código fonte por pastas e ficheiros, e as soluções arquiteturais adotadas no âmbito da unidade curricular de **Programação Móvel** (TeSP em Desenvolvimento de Aplicações Móveis, IPCA).

---

## Estrutura de Pastas e Distribuição de Componentes

Todo o código de lógica, estado e interface encontra-se estruturado de forma estrita dentro do diretório principal `lib/`, promovendo uma arquitetura limpa, legível e de fácil manutenção. Abaixo encontra-se o mapa detalhado de onde está cada elemento da aplicação:

### 1. `lib/core/` (O Núcleo da Aplicação)
Esta pasta centraliza as configurações globais, utilitários transversais e motores de lógica de negócio que servem toda a aplicação de forma desacoplada.
* `translations.dart`: O motor de internacionalização personalizado. É responsável por carregar e mapear as strings estáticas da aplicação para os **10 idiomas suportados** (incluindo Grego, Russo, Chinês, etc.). Contém os mapas de dicionário locais e faz a gestão defensiva de caracteres especiais (evitando quebras de renderização).
* `providers/`: Contém os gestores de estado da aplicação utilizando a biblioteca **Provider**:
    * `favorites_provider.dart`: Gere o estado da lista de favoritos do utilizador em tempo real. Sempre que um item é adicionado ou removido, notifica os ecrãs associados para atualizarem a interface de forma reativa. Sincroniza também as alterações localmente com o armazenamento do dispositivo.
    * `theme_provider.dart`: Controla a alternância global entre o Modo Escuro (**Dark Mode**) e o Modo Claro (**Light Mode**).

### 2. `lib/pages/` (Ecrãs Principais / Camada de View)
Cada ficheiro nesta pasta representa uma interface ou ecrã inteiro que o utilizador visualiza ao navegar:
* `splash_page.dart`: O ecrã de carregamento inicial (*Splash Screen*). Exibe o logótipo da aplicação com um efeito de animação de arranque fluida enquanto prepara os serviços básicos em segundo plano.
* `home_page.dart`: O centro de controlo visual da app. Apresenta o catálogo dinâmico de filmes e séries, a barra de navegação por separadores (**Geral**, **Filmes**, **Séries**), ordenações por categorias (Populares, Melhores, Recentes, Ordem Alfabética de A a Z) e o menu lateral para filtros avançados.
* `detalhes_page.dart`: A ficha técnica exaustiva de uma obra. Recebe os argumentos passados pelo ecrã anterior e exibe a sinopse, classificação, equipa técnica, estúdios, elenco de atores, as plataformas de streaming onde o conteúdo está disponível e o botão para reproduzir o trailer.
* `favoritos_page.dart`: Interface dedicada à biblioteca pessoal do utilizador. Permite ver todos os conteúdos guardados, filtrá-los com uma barra de pesquisa interna (ícone da lupa) e reorganizar os itens.

### 3. `lib/widgets/` (Componentes Visuais Reutilizáveis)
Aloja pequenos blocos visuais modulares que são partilhados por múltiplos ecrãs para evitar duplicação de código:
* `square_progress_loader.dart`: Um indicador de carregamento animado com formato quadrado personalizado. É invocado sempre que a aplicação está à espera de uma resposta assíncrona da rede (ex: ao carregar listas ou mudar de página).
* Componentes de cartões de filmes, cabeçalhos ou barras de pesquisa modulares que garantem a consistência visual da interface.

### 4. `lib/models/` (Modelos de Dados / Camada de Dados)
Contém as classes Dart fortemente tipadas que estruturam as respostas cruas recebidas da API para objetos manipuláveis pelo Flutter:
* Classes responsáveis por mapear e fazer o parse (deserialização) de objetos **JSON** provenientes do TMDB relativos a Filmes, Séries, Atores, Plataformas de streaming e Trailers. É aqui que reside a lógica defensiva contra erros de *Null Safety* (atribuindo strings de reserva como "Informação não disponível" caso os campos venham vazios).

### 5. `lib/main.dart` (O Ponto de Entrada)
O ficheiro mestre que arranca toda a aplicação. As suas funções são:
1.  Inicializar o ciclo de vida global da app.
2.  Injetar e configurar os `MultiProvider` (Estado de favoritos, idiomas e temas).
3.  Definir as rotas de navegação internas da aplicação.
4.  Definir a `SplashPage` como o ecrã de partida padrão.

---

## Detalhe Técnico das Funcionalidades da App

### Consumo de Dados em Tempo Real (API TMDB)
A aplicação liga-se de forma assíncrona aos servidores externos da **The Movie Database (TMDB) API** através de pedidos **HTTP**. Isto permite obter metadados atualizados ao segundo, incluindo imagens dos posters, trailers do YouTube e dados de disponibilidade geográfica em streaming.

### Sistema de Navegação, Filtragem e Ordenação Avançada
A `home_page.dart` expõe uma interface extremamente intuitiva composta por:
* **Separadores de Categoria:** Divisão imediata entre *Geral*, *Filmes* e *Séries*.
* **Filtros de Relevância:** Listagens dinâmicas segmentadas por *Populares*, *Melhores Classificados* (baseados em pontuações de 0 a 10) e *Recentes*.
* **Ordenação Alfabética:** Botão rápido para ordenar instantaneamente os títulos exibidos de A a Z.
* **Menu Lateral Expandido:** Dá acesso a filtros refinados por **Anos de Lançamento**, **Géneros/Categorias** e **Plataformas de Streaming** específicas.
* **Modo Família:** Um filtro de proteção parental integrado ativado por defeito que restringe e esconde de forma automática obras com classificação etária para maiores de 18 anos. Pode ser desativado nas definições.

### Persistência de Dados Local (`Shared Preferences`)
Para garantir uma excelente experiência de utilização, a aplicação não perde os dados quando o utilizador a fecha. O estado da lista de favoritos e as definições de preferência do utilizador (como o idioma selecionado e o tema escuro/claro) são guardados de forma permanente no armazenamento do telemóvel usando **Shared Preferences**.

### Experiência Visual e UI (Interface de Utilizador)
A identidade visual foi construída com foco na sobriedade, legibilidade e elegância:
* **Paleta de Cores:** Assenta numa combinação contrastante e apelativa.
* **Navegação Dinâmica:** O logótipo funciona como um atalho rápido — basta carregar nele para voltar instantaneamente ao topo ou à página principal.
* **Integração de Vídeo:** Ao clicar no trailer a partir da página de detalhes, a app faz a ponte direta com o ecossistema do **YouTube**.

### Tratamento Defensivo contra Erros (*Null Safety* & Caracteres)
A aplicação foi blindada contra falhas de execução inesperadas. Caso um filme não tenha tradução da sinopse ou dados técnicos na API para o idioma escolhido, o sistema injeta automaticamente o título original em Inglês ou exibe a mensagem padrão "Informação não disponível", assegurando que a aplicação nunca sofre uma quebra estrutural (*crash*).

---

## Informação Institucional e Autoria

O projeto foi totalmente concebido e implementado no âmbito do ecossistema de engenharia de software do **IPCA**:
* **Estudante:** Fábio Braga, n.º 36949
* **Unidade Curricular:** Computação Movel
* **Curso:** Aplicações Móveis
* **Data de Entrega:** Maio de 2026
