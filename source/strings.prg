// FWH strings multiple languages support


#include "FiveWin.ch"

static nLanguage := 0   // Initially will be set by LanguageID() function
// 1 English, 2 Spanish, 3 French, 4 Portugese, 5 German, 6 Italian

static aStrings := { ;
{ "Attention", "Atención", "Attention", "Atenção", "Achtung", "Attenzione" }, ;
{ "PDF Plugin Error", "Error del plugin de PDF", "Erreur de plugin du PDF", "Erro do plugin do PDF", ;
"PDF Plugin-Fehler", "Errore del plugin PDF" }, ;
{ "PDF not saved to send Email", "No se ha guardado el PDF a enviar por Email", ;
"PDF Non enregistré pour envoi Email", "PDF não foi salvo para mandar por email", ;
"PDF nicht gespeichert um E-Mail zu senden", "PDF non salvato per inviare e-mail" }, ;
{ "MS Word not installed", "MS Word no está instalado", "MS Word non installé", "MS Word não está instalado", ;
"MS Word ist nicht installiert", "MS Word non è installato" }, ;
{ "Failed to Create Word Document", "No se ha podido crear el documento de Word", ;
"Echec à la création du document Word", "Não foi possível criar o documento do Word", ;
"Fehler beim Erstellen des Word-Dokuments", "Impossibile creare il documento di Word" }, ;
{ "There is no output for export", "No hay nada que exportar", "Rien à exporter", "Nada para exportar", ;
"Nichts zu exportiren", "Non vi è alcuna uscita per l'esportazione" }, ;
{ "No .Doc file manipulation software installed", "No hay instalado software para usar ficheros .Doc", ;
"Pas de programme installé pour manipuler les fichiers .Doc", "Não há software instalado para usar arquivos .Doc", ;
"Keine .doc Bearbeitungssoftware installiert", ;
"Nessun installato. Software di manipolazione di file Doc" }, ;
{ "not found, imposible to continue", "no se ha encontrado, no se puede continuar", ;
"Pas trouvé, impossible de continuer", "não encontrado, impossível continuar", "nicht gefunden! Kann nicht fortsetzen", ;
"Non trovata. Impossible continuare" }, ;
{ "Printing Error", "Error de impresión", "Erreur impressión", "Erro de impressão", "Fehler beim Drucken", "Errore di stampa" }, ;
{ "View", "Visualizar", "Visualiser", "Visualizar", "Sehen Sie", "Visualizza" }, ;
{ "Excel not installed", "Excel no está instalado", "Excel non installé", "Excel não está instalado", ;
"Excel nicht installiert", "Excel non installato" }, ;
{ "Report width is greater than page width", "El ancho del informe es mayor que el ancho de la página", ;
"Largeur du Rapport supérieure à la largeur de la page", "A largura do relátorio é maior que a página", ;
"Breite des Reports ist größer als die Seitenbreite", "La larghezza del report è maggiore della larghezza pagina" }, ;
{ "Export to Excel is available only", "Solo está disponible exportar a Excel", ;
"Export vers Excel uniquement disponible", "Somente a exportação para o Excel está disponível", ;
"Nur Excel-Export ist verfügbar", "Esporta in Excel è disponibile solo" }, ;
{ "for Reports with ::bInit defined", "para reportes con ::bInit definido", "pour Rapports avec ::bInit défini", ;
"para relatórios com ::bInit definido", "Für Berichte, die mit :: bInit definiert sind", ;
"Per i Rapporti con definito ::bInit" }, ;
{ "Printing Preview", "Previsualización de Impresión", "visualisation de l'impression", ;
"Previsualização da impressão", "Druckvorschau", "Anteprima di stampa" }, ;
{ "&File", "&Fichero", "&Fichier", "Ar&quivos", "D&atei", "File" }, ;
{ "&Print", "&Imprimir", "&Imprimer", "&Imprimir", "&Druck", "Stampa" }, ;
{ "Print actual page", "Imprimir la página actual", "Imprimer la Page en Cours", "Imprimir a página atual", ;
"Aktuelle Seite drucken", "Stampa pagina attuale" }, ;
{ "&Exit", "&Salir", "&Quitter", "&Sair", "Exit", "&Uscita" }, ;
{ "Exit from preview", "Salir de la previsualización", "Quitter la Visualisation", "Sair da previsualização", ;
"Verlassen der Vorschau", "Esci da anteprima" }, ;
{ "Page", "Página", "Page", "Página", "Seite", "Pagina" }, ;
{ "&First", "&Primera", "&Première", "&Primeira", "Erste", "Prima" }, ;
{ "Go to first page", "Ir a la primera página", "Aller à la première page", "Ir para primeira página", ;
"Zur ersten Seite", "Vai alla prima pagina" }, ;
{ "&Previous", "&Anterior", "&Précédente", "&Anterior", "Vorherige", "Precedente" }, ;
{ "Go to previous page", "Ir a la página anterior", "Aller à la page précédente", "Ir para página anterior", ;
"Zur vorherigen Seite", "Vai alla pagina precedente" }, ;
{ "&Next", "&Siguiente", "&Suivante", "Pró&xima", "Nächste", "Successiva" }, ;
{ "Go to next page", "Ir a la siguiente página", "Aller à la page suivante", "Ir para a próxima página", ;
"Gehe zur nächsten Seite", "Vai alla pagina successiva" }, ;
{ "&Last", "&Ultima", "&Dernière", "Ú&ltima", "Letzte", "Ultimo" }, ;
{ "Go to last page", "Ir a la última página", "Aller à la dernière page",, "Zur letzten Seite", ;
"Vai all'ultima pagina" }, ;
{ "&Zoom", "&Zoom", "&Zoom", "&Zoom", "&Zoom", "Zoom" }, ;
{ "Page zoom", "Página ampliada con zoom", "zoom de la page", "zoom da página", "&Seite zoomen", "Zoom della pagina" }, ;
{ "&Normal", "&Normal", "&Normal", "&Normal", "&Normal", "Normale" }, ;
{ "Page unzoom", "Página normal", "Page normale", "Página normal", "Seite ungezoomt", "Pagina eliminare lo zoom" }, ;
{ "&Factor", "&Factor", "&Facteur", "&Fator", "Factor", "Fattore" }, ;
{ "Zoom factor", "Factor de zoom", "Facteur de Zoom", "Fator de zoom", "Zoom-Faktor", "Fattore di zoom" }, ;
{ "Factor", "Factor", "Facteur", "Fator", "Faktor", "Fattore" }, ;
{ "&Two pages", "&Dos páginas", "&Deux pages", "&Duas páginas", "Zwei Seiten", "Due pagine" }, ;
{ "Preview on two pages", "Previsualización en dos páginas", "Visualiser sur deux pages", ;
"Previsualização em duas páginas", "Vorschau auf zwei Seiten", "Anteprima su due pagine" }, ;
{ "One &page", "Una &página", "une &page", "Uma pá&gina", "Eine Seite", "Una pagina" }, ;
{ "Preview on one page", "Previsualización en una página", "Visualiser sur une page", ;
"Previsualização em uma página", "Vorschau auf einer Seite", "Anteprima di una pagina" }, ;
{ "Page number:", "Número de página:", "Numéro de la Page:", "Número de página:", "Seitenzahl:", "Numero di pagina:" }, ;
{ "Go to first page", "Ir a la primera página", "Aller à la première page", "Ir para a primeira página", "Zur ersten Seite", "Vai alla prima pagina" }, ;
{ "First", "Primera", "Première", "Primeira", "Erste", "Prima" }, ;
{ "&Page", "&Página", "&Page", "Pá&gina", "Seite", "Pagina" }, ;
{ "Preview on one page", "Previsualización en una página", "Visualiser sur une page", "Previsualização em uma página", "Vorschau auf einer Seite", "Anteprima di una pagina" }, ;
{ "Previous", "Anterior", "Précédente", "Anterior", "Zurück", "Precedente" }, ;
{ "Next", "Siguiente", "Suivante", "Próxima", "Weiter", "Successiva" }, ;
{ "Last", "Ultima", "Dernière", "Última", "Letzte", "Ultimo" }, ;
{ "Zoom", "Aumentar", "Zoom", "Aumentar", "Zoom", "Zoom" }, ;
{ "Two pages", "Dos páginas", "Deux pages", "Duas páginas", "Zwei Seiten", "Due pagine" }, ;
{ "Print", "Imprimir", "Imprimer", "Imprimir", "Druck", "Stampa" }, ;
{ "Save to DOC/PDF", "Guardar como DOC/PDF", "Enregistrer Format DOC/PDF", "Salvar como DOC/PDF", ;
"Speichern als DOC/PDF", "Salva per DOC / PDF" }, ;
{ "DOC Format", "Formato DOC", "Format DOC", "Formato DOC", "DOC-Format", "DOC Formato" }, ;
{ "PDF Format", "Formato PDF", "Format PDF", "Formato PDF", "PDF-Format", "Formato PDF" }, ;
{ "Export to PDF", "Exportar a PDF", "Exporter en PDF", "Exportar para PDF", "Export nach PDF", ;
"Esportazione in formato PDF" }, ;
{ "Send by email as PDF", "Enviar por email como PDF", "Evnoi par email format PDF", "Enviar PDF por email", ;
"PDF Senden per E-Mail", "Invia per e-mail in formato PDF" }, ;
{ "Export to MS Word", "Exportar a MS Word", "Exporter vers MS Word", "Exportar para MS Word", ;
"Export nach MS Word", "Esporta in MS Word" }, ;
{ "Export to Excel", "Exportar a Excel", "Exporter vers Excel", "Exportar para Excel", "Export nach Excel", ;
"Esporta in Excel" }, ;
{ "Exit", "Salir", "Quitter", "Sair", "Ende", "Exit" }, ;
{ "Preview", "Previsualizar", "Visualisation", "Previsualização", "Vorschau", "Anteprima" }, ;
{ "Save as", "Guardar como", "Enregistrer Sous", "Salvar como", "Speichern unter", "Salva con nome" }, ;
{ "Printing", "Imprimiendo", "Impression", "Imprimindo", "Drucke", "Stampa" }, ;
{ "Printing page", "Imprimiendo página", "Impression", "Imprimindo", "Druck von Seite", "Stampa" }, ;
{ "&Ok", "&Aceptar", "&OK", "C&onfirmar", "&Ok", "Ok" }, ;
{ "&Cancel", "&Cancelar", "&Annuler", "&Cancelar", "Abbrechen", "Annulla" }, ;
{ "Printing range", "Rango de impresión", "Portée Impression", "Intervalo de impressão", "Druckseitenbereich", ;
"Intervallo di stampa" }, ;
{ "All", "Todo", "Toutes", "Todo", "Alle", "Tutto" }, ;
{ "Current page", "Página actual", "Page en cours", "Página atual", "Aktuelle Seite", "La pagina attuale" }, ;
{ "Pages", "Páginas", "Pages", "Páginas", "Seiten", "Pagine" }, ;
{ "From", "Desde", "De", "De", "Von", "Da" }, ;
{ "To", "Hasta", "A", "Até", "Bis", "A" }, ;
{ "Undo", "Deshacer", "Annuler", "desfazer", "Rückgängig", "Undo" }, ;
{ "Redo", "Rehacer", "Rétablir", "Refazer", "Redo", "Redo" }, ;
{ "Cut", "Cortar", "couper", "Corte", "Schneiden", "Tagliare" }, ;
{ "Copy", "Copiar", "Copier", "cópia", "Kopieren", "Copia" }, ;
{ "Paste", "Pegar", "coller", "colar", "Einfügen", "Incolla" }, ;
{ "Delete", "Eliminar", "Supprimer", "Excluir", "Löschen", "Elimina" }, ;
{ "Font", "Fuente", "Police", "Font", "Schriftart", "Carattere" }, ;
{ "Print", "Imprimir", "Imprimer", "Imprimir", "Druck", "Stampa" }, ;
{ "Select All", "Seleccionar Todo", "Sélectionner Tout", "Selecionar tudo", "Alle Auswählen", "Seleziona Tutto" }, ;
{ "Align", "Alinear", "Aligner", "Alinhar", "Ausrichten", "Allinea" }, ;
{ "Left", "Izquierda", "Gauche", "à esquerda", "Links", "Sinistra" }, ;
{ "New", "Nuevo", "Nouveau", "Novo", "Neu", "Nuovo" }, ;
{ "ADO open", "ADO abrir", "ADO ouvrir", "ADO abrir", "ADO öffnen", "Apri ADO" }, ;
{ "Open", "Abrir", "ouvrir", "Abrir", "Öffnen", "Aprire" }, ;
{ "Center", "Centro", "Centrer", "center", "Mitte", "Centro" }, ;
{ "Right", "Derecha", "Droite", "certo", "Rechts", "Giusto" }, ;
{ "Justify", "Justificar", "Justifier", "justificar", "Ausrichten", "Giustifica" }, ;
{ "Attention", "¡Atención", "Attention", "Atenção", "Achtung", "Attenzione" }, ;
{ "Information", "Información", "Informations", "Informações", "Information","Informazioni" }, ;
{ "Wrong predefined cursor type!", "Wrong tipo de cursor predefinido!", "Mauvais catégorie de curseur prédéfini!" , ;
"Tipo cursor predefinido errado!", "Falscher vordefinierter Cursor-Typ!", "Tipo di cursore predefinito errato!" }, ;
{ "Want to end ?", "¿ Desea terminar ?", "Veulent mettre fin ? ", "Quer terminar ?", "Möchten Sie Beenden ?", "Vuoi terminare ?" },;
{ "Recent files", "Ficheros recientes", "Fichiers recents", "Arquivos recentes","Zuletzt verwendet","File recenti" },;
{ "Open this file", "Abrir este fichero", "Ouvrir ce fichier", "Abrir este arquivo","Datei öffnen","Apri questo file" },;
{ "Recent ADO connections", "Conexiones ADO recientes", "Connections ADO recentes", "Conecções ADO recentes","Zuletzt verwendete ADO-Verbindungen", "Connessioni ADO recenti" },;
{ "Recent ADO connections strings", "Cadenas de conexión ADO recientes", "Chaînes de connections ADO recentes", "Cadeias de conecções ADO recentes", "Zuletzt verwendete ADO-Verbindungsdaten", "Recenti stringhe di connessione ADO" },;
{ "Connect to this ADO database", "Conectar a esta base de datos ADO", "Connecter à cette base de données ADO", "Conectar a esta base de dados ADO", "Verbinde zu dieser ADO-Datenbank", "Connettiti con questo database ADO" },;
{ "Preferences", "Preferencias", "Préférences", "Preferências", "Präferenzen", "Preferenze" },;
{ "Natural order", "Orden natural", "Ordre natural", "Ordem natural","Keine Sortierung","Ordinamento naturale" },;
{ "Add", "Añadir", "Ajouter", "Adicionar","Hinzufügen","Aggiungi" },;
{ "Edit", "Editar", "Editer", "Editar","Bearbeiten","Modifica" },;
{ "Del", "Borrar", "Supprimer", "Excluir" ,"Löschen","Elimina"},;
{ "Top", "Inicio", "Début", "Início" ,"Anfang","Inizio"},;
{ "Bottom", "Final", "Fin", "Final","Ende","Fine" },;
{ "Search", "Buscar", "Chercher", "Procurar","Suchen","Ricerca" },;
{ "Index", "Orden", "Ordre", "Ordem" ,"Ordnung","Indice"},;
{ "Filter", "Filtro", "Filtre", "Filtro","Filter","Filtro" },;
{ "Relations", "Relaciones", "Relations", "Relações","Relation","Relazioni" },;
{ "Process", "Proceso", "Processus", "Processo","Prozess","Processi" },;
{ "Struct", "Estructura", "Structure", "Estrutura","Struktur","Struttura" },;
{ "Imp/Exp", "Imp/Exp", "Imp/Exp", "Imp/Exp","Import/Export","Importa/Esporta" },;
{ "Report", "Reporte", "Rapport", "Relatório","Report","Stampa" },;
{ "FileName", "Nombre del fichero", "Nom du fichier", "Nome do arquivo","Dateiname","Nome file" },;
{ "NON DELETED", "NO BORRADO", "NON SUPPRIMÉ", "NÃO EXCLUIDO","NICHT GELÖSCHT","NON CANCELLATO" },;
{ "nondeleted", "No borrado", "Non supprimé", "Não excluido","nicht gelöscht","Non cancellato" },;
{ "Ordered by", "Ordenado por", "Classé par", "Classificado por" ,"Sortiert nach","Ordinato per"},;
{ "Natural order", "Orden natural", "Ordre naturel", "Ordem natural","Unsortiert","Ordinamento naturale" },;
{ "Edit", "Editar", "Editer", "Editar","Bearbeiten","Modifica" },;
{ "Save", "Guardar", "Enregistrer", "Salvar","Speichern","Salva" },;
{ "Prev", "Anterior", "Anterieur", "Anterior","Vorher","Precedente" },;
{ "Value", "Valor", "Valeur", "Valor","Wert","Valore" },;
{ "Please select", "Por favor seleccione", "Choisissez", "Selecione","Wählen","Seleziona" },;
{ "Please select a DBF", "Por favor seleccione una DBF", "Choisissez un DBF", "Selecione um DBF","Wählen einer DBF","Seleziona un DBF" },;
{ "(Y/N)", "(S/N)", "(O/N)", "(S/N)","(J/N)","(S/N)" },;
{ "Index builder", "Constructor de índices", "Constructeur d´indexes", "Construtor de índices","Index erstellen","Costruzione indici" },;
{ "Expression", "Expresión", "Expression", "Expressão","Ausdruck","Espressione" },;
{ "Tag", "Tag", "Tag", "Tag","Tag","Tag" },;
{ "For", "Para", "Pour", "Para","Wenn","Per" },;
{ "While", "Mientras", "Pendant", "Enquanto","Während","Mentre" },;
{ "Unique", "Unico", "Unique", "Único","Eindeutig","Unico" },;
{ "Descending", "Descendente", "Descendant", "Descendente","Absteigend","Discendente" },;
{ "Memory", "Memoria", "Mémoire", "Memória","Speicher","Memoria" },;
{ "Scope", "Ambito", "Étendue", "Escopo","Sichtbar","Ambito" },;
{ "Record", "Registro", "Enregistrement", "Registro","Datensatz","Record" },;
{ "Rest", "Restantes", "Restant", "Resto","Restliche","Resto" },;
{ "Progress", "Progreso", "Progrès", "Progresso","Fortschritt","Progresso" },;
{ "Create", "Crear", "Créer", "Criar","Erzeugen","Creazione" },;
{ "fields", "campos", "champ", "campo","Felder","campi" },;
{ "Name", "Nombre", "Nom", "Nome","Name","Nome" },;
{ "Type", "Tipo", "Type", "Tipo","Typ","Tipo" },;
{ "Len", "Lon", "Lon", "Com","Länge","Lunghezza" },;
{ "Dec", "Dec", "Dec", "Dec","Dezimal","Decimali" },;
{ "Code", "Código", "Code", "Código","Code","Codice" },;
{ "Indexes of ", "Indices de ", "Index de ", "Índices de","Sortierungen von","Indici di" },;
{ "Order", "Orden", "Ordre", "Ordem","Sortierung","Ordine" },;
{ "TagName", "NombreTag", "NomTag", "NomeTag","TagName","Nometag" },;
{ "BagName", "NombreBag", "NomBag", "NomeBag","BagName","Nomebag" },;
{ "BagExt", "ExtBag", "ExtBag", "ExtBag","ExtBag","Bagext" },;
{ "Incremental", "Incremental", "Incrémental", "Incremental","Inkrementell","Incrementale" },;
{ "Key", "Clave", "Clé", "Chave","Schlüssel","Chiave" },;
{ "Help", "Ayuda", "Aide", "Ajuda","Hilfe","Aiuto" },;
{ "Import/Export for ", "Importar/Exportar para ", "Importer/Exporter vers ", "Importar/Exportar para ","Import/Export für ","Importa/Esporta per" },;
{ "PDF files | *.pdf |", "ficheros PDF | *.pdf |", "fichier PDF | *.pdf |", "arquivos PDF | *.pdf |","PDF-Dateien | *.pdf |","File PDF | *.pdf |", "archivi PDF | *.pdf |" },;
{ "Select PDF File to Save", "Seleccione el fichero PDF a guardar",, "Choisissez un fichier PDF pour sauvegarder", "Selecione um arquivo PDF para salvar","PDF-Datei zum Speichern auswählen","Seleziona il file pdf da salvare" },;
{ "Alert", "Alerta", "Alerte", "Alerta","Auswahl","Avviso" },;
{ "Select an option", "Seleccione una opción", "Choisissez une option", "Selecione uma opção","Wähle eine Option","Seleziona una opzione" },;
{ "Window", "Ventana", "Fenêtre", "Janela", "Fenster","Finestra" },;
{ "Tile Vertical", "Distribución vertical", "Mosaïque verticale", "Organizar verticalmente","Vertikal anordnen","Titolo verticale" },;
{ "Vertical arranges the windows as nonoverlapping tiles", "Organiza las ventanas verticalmente", "Organise les fenêtres verticalement", "Organiza as janelas verticalemente","Vertikal anordnen (nicht überlappend)","Organizza verticalmente le finestre" },;
{ "Tile Horizontal", "Distribución horizontal", "Mosaïque horizontale", "Organizar horizontalmente","Horizontal anordnen","Distribuzione orizzontale" },;
{ "Horizontal arranges the windows as nonoverlapping tiles", "Organiza las ventanas horizontalmente", "Mosaïque horizontale sans superposition", "Organizar as janelas horizontalmentesem superposição","Horizontal anordnen (nicht überlappend)","Organizza orizzontalmente le finestre" },;
{ "Cascade", "Cascada", "Cascade", "Cascata","Kaskadierend","A cascata" },;
{ "Arranges the windows so they overlap", "Organiza las ventanas para que no se oculten", "Organiser les fenêtres pour qu´elles ne se superposent pas", "Organiza as janelas para que não se sobreponham","Fenster anordnen (überlappend)","Organizza le finestre affinchè non si sovrappongano" },;
{ "Next Window", "Próxima ventana", "Fenêtre suivante", "Próxima janela","Nächstes Fenster","Finestra successiva" },;
{ "File to Save", "Fichero a guardar",, "fichier pour sauvegarder", "arquivo para salvar","Datei zum Speichern auswählen", "file da salvare" },;
{ "Selects the next window", "Selecciona la próxima ventana", "Selectionne la fenêtre suivante", "Selecione a próxima janela","Nächstes Fenster auswählen","Seleziona la prossima finestra" },;
{ "Arrange Icons", "Organiza los iconos", "Organise les icônes", "Organiza os ícones","Icons anordnen","Disponi icone" },;
{ "Arrange icons at the bottom of the window", "Organiza los iconos al final de la ventana", "Organiser les icônes au pied de la fenêtre", "Organizar os ícones no pé da janela","Icons am unteren Rand anordnen","Organizza le icone in fondo alla finestra" },;
{ "Iconize All", "Iconiza todas", "Reduire toutes", "Iconizar todas","Alle verbergen","Riduci tutto ad icona" },;
{ "Iconize all open windows", "Iconiza todas las ventanas abiertas", "Reduire toutes les fenêtres ouvertes", "Iconizar todas as janelas abertas","Alle offenen Fenster verbergen","Riduci a icona tuttte le finestre aperte" },;
{ "Close", "Cierra", "Fermer", "Fecha", "Alle", "Chiudi" },;
{ "Close All", "Cierra todas", "Fermer toutes", "Fecha todas","Alle schließen","Chiudi tutto" },;
{ "Close all open windows", "Cierra todas las ventanas abiertas", "Fermer toutes les fenêtres ouvertes", "Fechar todas as janelas abertas","Alle offenen Fenster schließen","Chiudi tutte le finestre aperte" },;
{ "Contents", "Contenidos", "Contenu", "Conteúdo","Inhalte","Contenuti" },;
{ "Show the help contents", "Muestra los contenidos de la ayuda", "Montrer le contenu de l´aide", "Mostrar o conteúdo da ajuda","Hilfethemen","Mostra i contenuti del file di aiuto" },;
{ "Search for Help on...", "Busca en la ayuda por...", "Rechecher de l´aide sur", "Procurar ajuda para","Suche für Hilfe über...","Ricerca nel file di help per..." },;
{ "Search the help for a specific item", "Busca la ayuda para un item específico", "Rechecher de l´aide sur un sujet spécifique", "Procurar ajuda para um ítem espécifico","Suche für Hilfe über ein bestimmtes Thema","Ricerca nel file di help per una specifica parola" },;
{ "Using help", "Usando la ayuda", "Utilisant l´aide", "Usando a ajuda","Hilfe benutzen","Uso dell'help" },;
{ "Show the help index", "Muestra el índice de la ayuda", "Montrer le catalogue de l´aide", "Mostrar o índice da ajuda","Hilfeindex zeigen","Mostra l'indice del file di help" },;
{ "About...", "Acerca de...", "Sur...", "A respeito de...", "Über...","Circa..." },;
{ "Displays program information and copyright", "Muestra información y derechos de copia del programa", "Afficher les informations et droits du programme", "Exibir os direitos e informações do programa","Copyright und Information","Mostra informazioni e copyright del programma" },;
{ "Default RDD", "RDD por defecto", "RDD par défaut", "RDD padrão","Standard für Datenbanktreiber","RDD standard" },;
{ "Open in shared mode", "Abrir en modo compartido", "Ouvrir en mode partagé", "Abrir em modo compartilhado","Öffnen für gemeinsamen Zugriff","Apri in modalità condivisa" },;
{ "No Help file defined with SetHelpFile()", "No se ha definido un fichero de ayuda usando SetHelpFile()", "Aucun fichier d´aide défini avec la fonction SetHelpFile()", "Nãu foi definido um arquivo de ajuda usando SetHelpFile()","Keine Hilfe definiert mit SetHelpFile()","Nessun file di help definito con SetHelpFile()" },;
{ "Want to delete this record ?", "¿ Desea eliminar este registro ?", "Supprimer cet enregistrment?", "Eliminar este registro?","Diesen Datensatz löschen?","Vuoi cancellare questo record ?" },;
{ "Expression builder", "Constructor de expresiones", "Générateur d´expression", "Construtor de expressões","Ausdrücke definieren","Costruzione espressione" },;
{ "Operators", "Operadores", "Operateurs", "Operadores" ,"Operatoren","Operatori" },;
{ "Functions", "Funciones", "Fonctions", "Funções","Funktionen","Funzioni" },;
{ "Relations of", "Relaciones de", "Relations de", "Relações de","Relationen","Relazioni" },;
{ "Rel.", "Rel.", "Rel.", "Rel.","Rel.","Rel." },;
{ "Child Alias", "Alias del hijo", "Alias du fils", "Alias do filho","Kind-Alias","Aree figlio" },;
{ "Additive", "Aditivo", "Additif", "Aditivo","Zusätzlich","Aggiuntive" },;
{ "Scoped", "Con ámbito", "Encadré", "Com ámbito","Sichtbar","Portata" },;
{ "Processes", "Procesos", "Processus", "Processos","Prozesse","Processi" },;
{ "Run", "Correr", "Executer", "Executar","Ausführen","Esegui" },;
{ "DELETED", "BORRADO", "SUPPRIMÉ", "EXCLUIDO","GELÖSCHT","CANCELLATO" },;
{ "Record updated", "Registro actualizado", "Enregistrement actualisé", "Registro atualizado","Datensatz aktualisiert","record modificato" },;
{ "DBF builder", "Constructor de DBF", "Générateur de DBF", "Construtor de DBF","DBF definieren und erzeugen","Costruzione DBF" },;
{ "Field Name", "Nombre campo", "Nom champ", "Nome campo","Feldname","Nome campo" },;
{ "FieldName", "Nombre campo", "Nom champ", "Nome campo","Feldname","Nome campo" },;
{ "Move Up", "Mover arriba", "Déplacer vers le haut", "Mover para cima","Aufwärts bewegen","Muovi in su" },;
{ "Move Down", "Mover abajo", "Déplacer vers le bas", "Mover para cima" ,"Abwärts bewegen","Muovi in giu" },;
{ "DBF Name:", "Nombre DBF:", "Nom DBF:", "Nome DBF:","DBF-Name:","Nome DBF" },;
{ "Language", "Lenguaje", "Idiome", "Idioma" ,"Sprache","Linguaggio" },;
{ "English", "Inglés", "Français", "Português","Englisch","Inglese" },;
{ "Spanish", "Español", "Espagnol", "Espanhol","Spanisch","Spagnolo" },;
{ "French", "Frances", "Français", "Francês","Französisch","Francese" },;
{ "German", "Alemán", "Allemand", "Alemão","Deutsch","Tedesco" },;
{ "Portuguese", "Portugues", "Portugais", "Português","Portugiesisch","Portoghese" },;
{ "Italian", "Italiano", "Italien", "Italiano","Italienisch","Italiano" },;
{ "Databases", "Bases de datos", "Base de données", "Base de dados","Datenbanken","Database" },;
{ "Query", "Consulta", "Requête", "Consulta","Abfrage","Richiesta" },;
{ "Query builder", "Constructor de consultas", "Générateur de requêtes", "Construtor de consultas","Abfrage definieren","Contruzione richiesta" },;
{ "Operation", "Operación", "Operation", "Operação","Operation","Operazione" },;
{ "Equal", "Igual", "Égal", "Igual","Gleich","Uguale" },;
{ "Different", "Diferente", "Different", "Diferente","Verschieden","differenre" },;
{ "Like", "Como", "Comme", "Como","Wie","Simile" },;
{ "Equal", "Igual", "Égal", "Igual","Gleich","Uguale" },;
{ "Select a table", "Seleccionar una tabla", "Choisir un tableau", "Selecionar uma tabela","Wähle eine Tabelle","Selezona una tabella" },;
{ "Delete for", "Borrar por", "Supprimer si", "Excluir se","Lösche wenn","Cancella per" },;
{ "Delete records of", "Borrar registros de", "Supprimer enregistrements de", "Excluir registros de","Lösche Datensätze mit","Cancella records per" },;
{ "For condition", "Condición para", "Condition SI", "Condição SE","Bedingung","Condizione per" },;
{ "While condition", "Condición mientras", "Condition pendant", "Condição enquanto","Solange","Condizione finchè" },;
{ "Total deleted", "Borrados en total", "Total supprimés", "Total excluídos","Insgesamt gelöscht","Tolale cancellati" },;
{ "Number of records", "Número de registros", "Quantité d´enregistrements", "Quantidade de registros","Zahl der Datensätze","Numero di records" },;
{ "Recall", "Recuperar", "Récupérer", "Recuperar","Wiederherstellen","Recupera" },;
{ "The string", "La cadena", "La chaîne", "A cadeia","Das Wort","La stringa" },;
{ "for language", "para el idioma", "pour l´idiome", "para o idioma","für die Sprache","per il linguaggio" },;
{ "defined from", "definida en", "définie à partir de", "definida de","aufgerufen von","definita da" },;
{ "line", "línea", "ligne", "linha","Zeile","linea" },;
{ "is not defined in FWH strings", "no está traducida en las cadenas de FWH", "non traduit dans les chaînes de FWH", "não está traduzida nas cadeias de FWH","ist in den FWH-Strings nicht definiert","Non è definita nelle stringhe FWH" },;
{ "Please add it to FWH\source\function\strings.prg",;
  "Por favor incluir en FWH\source\function\strings.prg",;
"Ajouter s´il vouz plait dans FWH\source\function\strings.prg",;
"Por favor incluir en FWH\source\function\strings.prg","Bitte ergänze es in FWH\source\function\strings.prg","Pewr vavore caricatela nell'archivio FWH\source\function\strings.prg" },;
{ "freeimage.dll not found", "no se encuentra freeimage.dll", "manque freeimage.dll", "freeimage.dll não encontrada","Freeimage.dll nicht gefunden","freeimage.dll non trovata" },;
{ "file not found", "fichero no encontrado", "fichier pas trouvé", "arquivo não encontrado" ,"Datei nicht gefunden","Archivio non trovato"},;
{ "¿", "¿", "?", "?","?","?" },;
{ "Excel not installed", "No está instalado Excel", "Excel non installé", "Excel não instalado","Excel nicht gefunden","Excel non installato" },;
{ "Could not set the format", "No puede establecerse el formato", "Il n´a pas été possible d´établir le format", "Não foi possível estabelecer o formato","Kann das Format nicht festlegen","Non posso impostare il formato" },;
{ "No spreadsheet software installed",;
"No hay software instalado para visualizar hojas de cálculo",;
"Il n´y a pas de programme installé por visualiser les feuilles de calcul",;
"Não tem software instalado para visualizar as folhas de cálculo","Keine Tabellekalkulationssoftware installiert","Nessun software di foglio elettronico installato" },;
{ "to column", "hasta la columna", "jusqu´à la colonne", "até a coluna","nach Reihe","alla colonna" },;
{ "to excel", "a excel", "vers excel", "para excel","nach Excel","in excel" },;
{ "to calc", "a hoja de cálculo", "vers feuille de calcul", "para folha de cálculo","nach Calc","in calcolo" },;
{ "to dbf", "a la DBF", "vers DBF", "para DBF","nach DBF","in dbf" },;
{ "Please select a database", "Por favor seleccione una base de datos", "S´il vous plait choisissez une base de données", "Por favor selecione uma base de dados","Bitte wähle eine Datenbank","Seleziona un database" },;
{ "DBF file| *.dbf|Access file| *.mdb|Access 2010 file | *.accdb|SQLite file| *.db|",;
"Fichero DBF| *.dbf|Fichero Access| *.mdb|Fichero Access 2010| *.accdb|Fichero SQLite| *.db|",;
"Fichier DBF| *.dbf|Fichier Access| *.mdb|Fichier Access 2010| *.accdb|Fichier SQLite| *.db|",;
"Arquivo DBF| *.dbf|Arquivo Access| *.mdb|Arquivo Access 2010| *.accdb|Arquivo SQLite| *.db|",;
"DBF Datenbank| *.dbf|Access Datenbank| *.mdb|Access 2010 Datenbank| *.accdb|SQLite Datenbank| *.db|",;
"File DBF| *.dbf|File Access| *.mdb|File Access 2010 |*.accdb|SQLite file| *.db|" },;
{ "Excel", "Excel", "Excel", "Excel", "Excel","Excel" },;
{ "Select", "Seleccione", "Sélectionner", "Selecionar", "Wählen", "Selezionare" },;
{ "Modify DBF structure", "Modificar estructura DBF", "Changement structure DBF", "Alterar estrutura do DBF", "DBF-Struktur bearbeiten", "Modifica struttura DBF" },;
{ "Item", "Item", "Item", "Item", "Item","Item" }, ;
{ "Area", "Area", "Area", "Area", "Area","Area" }, ;
{ "Items", "Items", "Items", "Items", "Items","Items" }, ;
{ "Properties", "Propiedades", "Properties", "Properties", "Properties","Properties" } ,;
{ "Grid Setting", "Configurar Grid", "Grid Setting", "Grid Setting", "Grid Setting","Grid Setting" } ;
}

static aMissing := {}

//----------------------------------------------------------------------------//

function FWString( cString , lMessage )

   local nAt
   DEFAULT lMessage := .t.
   
   if LanguageID() == 1
      return cString
   elseif ( nAt := AScan( aStrings, { | aString | Upper( aString[ 1 ] ) == Upper( cString ) } ) ) != 0
      if Len( aStrings[ nAt ] ) >= LanguageID()
         return IfNil( aStrings[ nAt ][ LanguageID() ], cString )
      endif
   else
      if '&' $ cString
         cString  := StrTran( cString, '&', '' )
         if ( nAt := AScan( aStrings, { | aString | Upper( aString[ 1 ] ) == Upper( cString ) } ) ) != 0
            if Len( aStrings[ nAt ] ) >= LanguageID()
               return '&' + IfNil( aStrings[ nAt ][ LanguageID() ], cString )
            endif
         endif
      endif
      if lMessage
         MsgInfo( FWString( "The string" ) + ': "' + cString + '" ' + ;
               FWString( "for language" ) + " " + ;
               { "EN", "ES", "FR", "PT", "DE", "IT" }[ LanguageID() ] + CRLF + ;
               FWString( "defined from" ) + ": " + ProcName( 1 ) + " " + ;
               FWString( "line" ) + " " + ;
               AllTrim( Str( ProcLine( 1 ) ) ) + " in " + ProcFile( 1 ) + CRLF + ;
               FWString( "is not defined in FWH strings" ) + CRLF + ;
               FWString( "Please add it to FWH\source\function\strings.prg" ) )
      endif         
      AAdd( aMissing, cString )
   endif

return cString

//----------------------------------------------------------------------------//

function FWSetLanguage( nNewLanguage )

   local nOldLanguage := LanguageID()

   if ! Empty( nNewLanguage )
      nLanguage = Max( 1, Min( nNewLanguage, Len( aStrings[ 1 ] ) ) )
   endif

return nOldLanguage

//----------------------------------------------------------------------------//

function FWAddLanguage( aLang, nLang )

   if ValType( aLang ) == 'A' .and. ! Empty( aLang )
      aStrings    := ArrTranspose( aStrings )
      if nLang == nil .or. nLang > Len( aStrings )
         AAdd( aStrings, aLang )
         nLang := Len( aStrings )
      else
         aStrings[ nLang ] := aLang
      endif
      aStrings    := ArrTranspose( aStrings )
      FWSetLanguage( nLang )
   endif

return nLang

//----------------------------------------------------------------------------//

function FWMissingStrings()

   local cResult := ""

   AEval( aMissing, { | cString | cResult += Space( 7 ) + '{ "' + cString + ;
                                  '", "" },;' + CRLF } )
   if ! Empty( cResult )
      MemoEdit( cResult, "Copy and paste in FWH\source\function\strings.prg" )
   endif

return cResult

//----------------------------------------------------------------------------//

function FWAddString( aString )

return AAdd( aStrings, aString )

//------------------------------------------------------------------------------

function FWGetStrings()
RETURN aStrings


//----------------------------------------------------------------------------//

static function LanguageID()

   if Empty( nLanguage )
      nLanguage   = Max( 1, AScan( { "EN", "ES", "FR", "PT", "DE", "IT" },;
                        Upper( Left( HB_LangSelect(), 2 ) ) ) )
   endif

return nLanguage

//----------------------------------------------------------------------------//

function FWLoadStrings( cFileName )

   local cLine, n := 1

   DEFAULT cFileName := cFilePath( GetModuleFileName( GetInstance() ) ) + ;
                        "fwstrings.ini"

   while ! Empty( cLine := GetPvProfString( "strings", AllTrim( Str( n++ ) ), "", cFileName ) )
      AAdd( aStrings , { AllTrim( StrToken( cLine, 1, "|" ) ),;
                        AllTrim( StrToken( cLine, 2, "|" ) ),;
                        AllTrim( StrToken( cLine, 3, "|" ) ),;
                        AllTrim( StrToken( cLine, 4, "|" ) ),;
                        AllTrim( StrToken( cLine, 5, "|" ) ),;
                        AllTrim( StrToken( cLine, 6, "|" ) ) } )
   end

RETURN nil

//----------------------------------------------------------------------------//

function FWSaveStrings( cFileName , aNewStrings )

   local cText := "[strings]" + CRLF, n

   DEFAULT cFileName := cFilePath( GetModuleFileName( GetInstance() ) ) + ;
                        "fwstrings.ini"

   DEFAULT aNewStrings := aStrings

   for n = 1 to Len( aNewStrings )
      cText += AllTrim( Str( n ) ) + "="
      AEval( aNewStrings[ n ], { | c | cText += If( c != nil, c, "" ) + "|" } )
      cText += CRLF
   next
   MemoWrit( cFileName , cText )
return nil

//----------------------------------------------------------------------------//

function FWEditStrings()

   XBROWSER aStrings FASTEDIT AUTOSORT SETUP BrwSetup( oBrw )

return nil

//----------------------------------------------------------------------------//

static function BrwSetUp( oBrw )

   oBrw:aCols[ 1 ]:cHeader = "English"
   oBrw:aCols[ 2 ]:cHeader = "Spanish"
   oBrw:aCols[ 3 ]:cHeader = "French"
   oBrw:aCols[ 4 ]:cHeader = "Portuguese"
   oBrw:aCols[ 5 ]:cHeader = "Italian"
   oBrw:aCols[ 6 ]:cHeader = "German"

   AEval( oBrw:aCols, { | oCol | oCol:nWidth := 200 } )

   ADD TO oBrw AT 1 DATA oBrw:BookMark HEADER " Nº "

return nil

//----------------------------------------------------------------------------//