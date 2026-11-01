import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en", mandarin = "zh-Hans", hindi = "hi", spanish = "es", arabic = "ar"
    case french = "fr", portuguese = "pt", german = "de", italian = "it"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .english: return "English"
        case .mandarin: return "中文 · Mandarin"
        case .hindi: return "हिन्दी · Hindi"
        case .spanish: return "Español · Spanish"
        case .arabic: return "العربية · Arabic"
        case .french: return "Français · French"
        case .german: return "Deutsch · German"
        case .italian: return "Italiano · Italian"
        case .portuguese: return "Português · Portuguese"
        }
    }
    var isRightToLeft: Bool { self == .arabic }
    static var saved: Self {
        Self(rawValue: UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "en") ?? .english
    }
}

extension Notification.Name {
    static let myEventLanguageChanged = Notification.Name("MyEventLanguageChanged")
}

func tr(_ key: String) -> String { Translations.text(key, language: .saved) }

enum Translations {
    static func text(_ key: String, language: AppLanguage) -> String {
        values[key]?[language.rawValue] ?? key
    }
    static let values: [String: [String: String]] = {
        let json = #"""
{
  "General": {
    "en": "General",
    "zh-Hans": "常规",
    "hi": "सामान्य",
    "es": "General",
    "ar": "عام",
    "fr": "Général",
    "pt": "Geral",
    "de": "Allgemein",
    "it": "Generali"
  },
  "Accounts": {
    "en": "Accounts",
    "zh-Hans": "账户",
    "hi": "खाते",
    "es": "Cuentas",
    "ar": "الحسابات",
    "fr": "Comptes",
    "pt": "Contas",
    "de": "Konten",
    "it": "Account"
  },
  "Permissions": {
    "en": "Permissions",
    "zh-Hans": "权限",
    "hi": "अनुमतियाँ",
    "es": "Permisos",
    "ar": "الأذونات",
    "fr": "Autorisations",
    "pt": "Permissões",
    "de": "Berechtigungen",
    "it": "Autorizzazioni"
  },
  "Settings": {
    "en": "Settings",
    "zh-Hans": "设置",
    "hi": "सेटिंग्स",
    "es": "Ajustes",
    "ar": "الإعدادات",
    "fr": "Réglages",
    "pt": "Ajustes",
    "de": "Einstellungen",
    "it": "Impostazioni"
  },
  "Settings…": {
    "en": "Settings…",
    "zh-Hans": "设置…",
    "hi": "सेटिंग्स…",
    "es": "Ajustes…",
    "ar": "الإعدادات…",
    "fr": "Réglages…",
    "pt": "Ajustes…",
    "de": "Einstellungen…",
    "it": "Impostazioni…"
  },
  "Language:": {
    "en": "Language:",
    "zh-Hans": "语言：",
    "hi": "भाषा:",
    "es": "Idioma:",
    "ar": "اللغة:",
    "fr": "Langue :",
    "pt": "Idioma:",
    "de": "Sprache:",
    "it": "Lingua:"
  },
  "Language": {
    "en": "Language",
    "zh-Hans": "语言",
    "hi": "भाषा",
    "es": "Idioma",
    "ar": "اللغة",
    "fr": "Langue",
    "pt": "Idioma",
    "de": "Sprache",
    "it": "Lingua"
  },
  "Global shortcut:": {
    "en": "Global shortcut:",
    "zh-Hans": "全局快捷键：",
    "hi": "वैश्विक शॉर्टकट:",
    "es": "Atajo global:",
    "ar": "الاختصار العام:",
    "fr": "Raccourci global :",
    "pt": "Atalho global:",
    "de": "Globales Tastenkürzel:",
    "it": "Scorciatoia globale:"
  },
  "Press your shortcut…": {
    "en": "Press your shortcut…",
    "zh-Hans": "按下快捷键…",
    "hi": "शॉर्टकट दबाएँ…",
    "es": "Pulsa el atajo…",
    "ar": "اضغط الاختصار…",
    "fr": "Tapez la combinaison…",
    "pt": "Pressione o atalho…",
    "de": "Tastenkürzel drücken…",
    "it": "Premi la scorciatoia…"
  },
  "Cancel": {
    "en": "Cancel",
    "zh-Hans": "取消",
    "hi": "रद्द करें",
    "es": "Cancelar",
    "ar": "إلغاء",
    "fr": "Annuler",
    "pt": "Cancelar",
    "de": "Abbrechen",
    "it": "Annulla"
  },
  "Select text and press the shortcut. The event is added immediately.": {
    "en": "Select text and press the shortcut. The event is added immediately.",
    "zh-Hans": "选择文本并按下快捷键，即可立即添加日程。",
    "hi": "पाठ चुनें और शॉर्टकट दबाएँ। इवेंट तुरंत जुड़ जाएगा।",
    "es": "Selecciona texto y pulsa el atajo. El evento se añade al instante.",
    "ar": "حدد النص واضغط الاختصار. يُضاف الحدث فورًا.",
    "fr": "Sélectionnez un texte et utilisez le raccourci. L'événement est ajouté immédiatement.",
    "pt": "Selecione o texto e pressione o atalho. O evento é adicionado imediatamente.",
    "de": "Text auswählen und das Tastenkürzel drücken. Der Termin wird sofort hinzugefügt.",
    "it": "Seleziona il testo e premi la scorciatoia. L'evento viene aggiunto subito."
  },
  "Default duration:": {
    "en": "Default duration:",
    "zh-Hans": "默认时长：",
    "hi": "डिफ़ॉल्ट अवधि:",
    "es": "Duración predeterminada:",
    "ar": "المدة الافتراضية:",
    "fr": "Durée par défaut :",
    "pt": "Duração padrão:",
    "de": "Standarddauer:",
    "it": "Durata predefinita:"
  },
  "Default duration": {
    "en": "Default duration",
    "zh-Hans": "默认时长",
    "hi": "डिफ़ॉल्ट अवधि",
    "es": "Duración predeterminada",
    "ar": "المدة الافتراضية",
    "fr": "Durée par défaut",
    "pt": "Duração padrão",
    "de": "Standarddauer",
    "it": "Durata predefinita"
  },
  "Default time:": {
    "en": "Default time:",
    "zh-Hans": "默认时间：",
    "hi": "डिफ़ॉल्ट समय:",
    "es": "Hora predeterminada:",
    "ar": "الوقت الافتراضي:",
    "fr": "Heure par défaut :",
    "pt": "Horário padrão:",
    "de": "Standardzeit:",
    "it": "Ora predefinita:"
  },
  "Default time": {
    "en": "Default time",
    "zh-Hans": "默认时间",
    "hi": "डिफ़ॉल्ट समय",
    "es": "Hora predeterminada",
    "ar": "الوقت الافتراضي",
    "fr": "Heure par défaut",
    "pt": "Horário padrão",
    "de": "Standardzeit",
    "it": "Ora predefinita"
  },
  "15 minutes": {
    "en": "15 minutes",
    "zh-Hans": "15分钟",
    "hi": "15 मिनट",
    "es": "15 minutos",
    "ar": "15 دقيقة",
    "fr": "15 minutes",
    "pt": "15 minutos",
    "de": "15 Minuten",
    "it": "15 minuti"
  },
  "30 minutes": {
    "en": "30 minutes",
    "zh-Hans": "30分钟",
    "hi": "30 मिनट",
    "es": "30 minutos",
    "ar": "30 دقيقة",
    "fr": "30 minutes",
    "pt": "30 minutos",
    "de": "30 Minuten",
    "it": "30 minuti"
  },
  "1 hour": {
    "en": "1 hour",
    "zh-Hans": "1小时",
    "hi": "1 घंटा",
    "es": "1 hora",
    "ar": "ساعة واحدة",
    "fr": "1 heure",
    "pt": "1 hora",
    "de": "1 Stunde",
    "it": "1 ora"
  },
  "1 hour 30 minutes": {
    "en": "1 hour 30 minutes",
    "zh-Hans": "1小时30分钟",
    "hi": "1 घंटा 30 मिनट",
    "es": "1 hora y 30 minutos",
    "ar": "ساعة و30 دقيقة",
    "fr": "1 h 30",
    "pt": "1 hora e 30 minutos",
    "de": "1 Stunde 30 Minuten",
    "it": "1 ora e 30 minuti"
  },
  "2 hours": {
    "en": "2 hours",
    "zh-Hans": "2小时",
    "hi": "2 घंटे",
    "es": "2 horas",
    "ar": "ساعتان",
    "fr": "2 heures",
    "pt": "2 horas",
    "de": "2 Stunden",
    "it": "2 ore"
  },
  "Without a recognized date: tomorrow at the default time. Without an end time: default duration. Time zone:": {
    "en": "Without a recognized date: tomorrow at the default time. Without an end time: default duration. Time zone:",
    "zh-Hans": "未识别到日期：明天的默认时间。未指定结束时间：使用默认时长。时区：",
    "hi": "तारीख न मिले: कल डिफ़ॉल्ट समय पर। समाप्ति समय न मिले: डिफ़ॉल्ट अवधि। समय क्षेत्र:",
    "es": "Sin fecha reconocida: mañana a la hora predeterminada. Sin hora final: duración predeterminada. Zona horaria:",
    "ar": "بدون تاريخ معروف: غدًا في الوقت الافتراضي. بدون وقت انتهاء: المدة الافتراضية. المنطقة الزمنية:",
    "fr": "Sans date reconnue : demain à l'heure par défaut. Sans heure de fin : durée par défaut. Fuseau :",
    "pt": "Sem data reconhecida: amanhã no horário padrão. Sem horário de término: duração padrão. Fuso horário:",
    "de": "Ohne erkanntes Datum: morgen zur Standardzeit. Ohne Endzeit: Standarddauer. Zeitzone:",
    "it": "Senza data riconosciuta: domani all'ora predefinita. Senza ora di fine: durata predefinita. Fuso orario:"
  },
  "Creating event…": {
    "en": "Creating event…",
    "zh-Hans": "正在创建日程…",
    "hi": "इवेंट बनाया जा रहा है…",
    "es": "Creando evento…",
    "ar": "جارٍ إنشاء الحدث…",
    "fr": "Création en cours…",
    "pt": "Criando evento…",
    "de": "Termin wird erstellt…",
    "it": "Creazione evento…"
  },
  "Text processed on this Mac": {
    "en": "Text processed on this Mac",
    "zh-Hans": "文本在此Mac上处理",
    "hi": "पाठ इसी Mac पर संसाधित होता है",
    "es": "Texto procesado en este Mac",
    "ar": "تتم معالجة النص على هذا Mac",
    "fr": "Texte traité sur ce Mac",
    "pt": "Texto processado neste Mac",
    "de": "Text wird auf diesem Mac verarbeitet",
    "it": "Testo elaborato su questo Mac"
  },
  "Help (English)": {
    "en": "Help (English)",
    "zh-Hans": "帮助（英语）",
    "hi": "सहायता (अंग्रेज़ी)",
    "es": "Ayuda (inglés)",
    "ar": "المساعدة (بالإنجليزية)",
    "fr": "Aide (anglais)",
    "pt": "Ajuda (inglês)",
    "de": "Hilfe (Englisch)",
    "it": "Aiuto (inglese)"
  },
  "Add events to:": {
    "en": "Add events to:",
    "zh-Hans": "将日程添加到：",
    "hi": "इवेंट यहाँ जोड़ें:",
    "es": "Añadir eventos a:",
    "ar": "إضافة الأحداث إلى:",
    "fr": "Ajouter les événements dans :",
    "pt": "Adicionar eventos a:",
    "de": "Termine hinzufügen zu:",
    "it": "Aggiungi eventi a:"
  },
  "A copy is created in each selected calendar.": {
    "en": "A copy is created in each selected calendar.",
    "zh-Hans": "每个选中的日历都会创建一个副本。",
    "hi": "हर चुने हुए कैलेंडर में एक प्रति बनती है।",
    "es": "Se crea una copia en cada calendario seleccionado.",
    "ar": "تُنشأ نسخة في كل تقويم محدد.",
    "fr": "Une copie est créée dans chaque calendrier coché.",
    "pt": "Uma cópia é criada em cada calendário selecionado.",
    "de": "In jedem ausgewählten Kalender wird eine Kopie erstellt.",
    "it": "Viene creata una copia in ogni calendario selezionato."
  },
  "Allow calendar access…": {
    "en": "Allow calendar access…",
    "zh-Hans": "允许访问日历…",
    "hi": "कैलेंडर पहुँच की अनुमति दें…",
    "es": "Permitir acceso al calendario…",
    "ar": "السماح بالوصول إلى التقويم…",
    "fr": "Autoriser l'accès aux calendriers…",
    "pt": "Permitir acesso ao calendário…",
    "de": "Kalenderzugriff erlauben…",
    "it": "Consenti accesso ai calendari…"
  },
  "No calendars available. Add an account in Calendar on this Mac.": {
    "en": "No calendars available. Add an account in Calendar on this Mac.",
    "zh-Hans": "没有可用日历。请在此Mac的日历应用中添加账户。",
    "hi": "कोई कैलेंडर उपलब्ध नहीं। इस Mac के Calendar में खाता जोड़ें।",
    "es": "No hay calendarios disponibles. Añade una cuenta en Calendario en este Mac.",
    "ar": "لا توجد تقاويم متاحة. أضف حسابًا في تطبيق التقويم على هذا Mac.",
    "fr": "Aucun calendrier disponible. Ajoutez un compte dans Calendrier sur ce Mac.",
    "pt": "Nenhum calendário disponível. Adicione uma conta no Calendário deste Mac.",
    "de": "Keine Kalender verfügbar. Fügen Sie in Kalender auf diesem Mac ein Konto hinzu.",
    "it": "Nessun calendario disponibile. Aggiungi un account in Calendario su questo Mac."
  },
  "Account": {
    "en": "Account",
    "zh-Hans": "账户",
    "hi": "खाता",
    "es": "Cuenta",
    "ar": "حساب",
    "fr": "Compte",
    "pt": "Conta",
    "de": "Konto",
    "it": "Account"
  },
  "Read only": {
    "en": "Read only",
    "zh-Hans": "只读",
    "hi": "केवल पढ़ने के लिए",
    "es": "Solo lectura",
    "ar": "للقراءة فقط",
    "fr": "Lecture seule",
    "pt": "Somente leitura",
    "de": "Schreibgeschützt",
    "it": "Sola lettura"
  },
  "Some selected destinations are no longer available.": {
    "en": "Some selected destinations are no longer available.",
    "zh-Hans": "部分选中的目标日历已不可用。",
    "hi": "कुछ चुने हुए गंतव्य अब उपलब्ध नहीं हैं।",
    "es": "Algunos destinos seleccionados ya no están disponibles.",
    "ar": "بعض الوجهات المحددة لم تعد متاحة.",
    "fr": "Certaines destinations ne sont plus disponibles.",
    "pt": "Alguns destinos selecionados não estão mais disponíveis.",
    "de": "Einige ausgewählte Ziele sind nicht mehr verfügbar.",
    "it": "Alcune destinazioni selezionate non sono più disponibili."
  },
  "Remove unavailable destinations": {
    "en": "Remove unavailable destinations",
    "zh-Hans": "移除不可用的目标",
    "hi": "अनुपलब्ध गंतव्य हटाएँ",
    "es": "Eliminar destinos no disponibles",
    "ar": "إزالة الوجهات غير المتاحة",
    "fr": "Retirer les destinations indisponibles",
    "pt": "Remover destinos indisponíveis",
    "de": "Nicht verfügbare Ziele entfernen",
    "it": "Rimuovi destinazioni non disponibili"
  },
  "Manage accounts…": {
    "en": "Manage accounts…",
    "zh-Hans": "管理账户…",
    "hi": "खाते प्रबंधित करें…",
    "es": "Gestionar cuentas…",
    "ar": "إدارة الحسابات…",
    "fr": "Gérer les comptes…",
    "pt": "Gerenciar contas…",
    "de": "Konten verwalten…",
    "it": "Gestisci account…"
  },
  "Refresh": {
    "en": "Refresh",
    "zh-Hans": "刷新",
    "hi": "ताज़ा करें",
    "es": "Actualizar",
    "ar": "تحديث",
    "fr": "Actualiser",
    "pt": "Atualizar",
    "de": "Aktualisieren",
    "it": "Aggiorna"
  },
  "Only accounts synced with macOS Calendar are available.": {
    "en": "Only accounts synced with macOS Calendar are available.",
    "zh-Hans": "仅显示与macOS日历同步的账户。",
    "hi": "केवल macOS Calendar से सिंक हुए खाते उपलब्ध हैं।",
    "es": "Solo están disponibles las cuentas sincronizadas con Calendario de macOS.",
    "ar": "تتوفر فقط الحسابات المتزامنة مع تقويم macOS.",
    "fr": "Seuls les comptes synchronisés avec Calendrier de macOS sont disponibles.",
    "pt": "Somente contas sincronizadas com o Calendário do macOS estão disponíveis.",
    "de": "Nur mit macOS Kalender synchronisierte Konten sind verfügbar.",
    "it": "Sono disponibili solo gli account sincronizzati con Calendario di macOS."
  },
  "Calendars": {
    "en": "Calendars",
    "zh-Hans": "日历",
    "hi": "कैलेंडर",
    "es": "Calendarios",
    "ar": "التقاويم",
    "fr": "Calendriers",
    "pt": "Calendários",
    "de": "Kalender",
    "it": "Calendari"
  },
  "Show calendar destinations and add events.": {
    "en": "Show calendar destinations and add events.",
    "zh-Hans": "显示目标日历并添加日程。",
    "hi": "कैलेंडर गंतव्य दिखाएँ और इवेंट जोड़ें।",
    "es": "Mostrar los calendarios de destino y añadir eventos.",
    "ar": "عرض التقاويم الوجهة وإضافة الأحداث.",
    "fr": "Afficher les destinations et ajouter les événements.",
    "pt": "Mostrar os calendários de destino e adicionar eventos.",
    "de": "Zielkalender anzeigen und Termine hinzufügen.",
    "it": "Mostra i calendari di destinazione e aggiungi eventi."
  },
  "Accessibility": {
    "en": "Accessibility",
    "zh-Hans": "辅助功能",
    "hi": "सुलभता",
    "es": "Accesibilidad",
    "ar": "تسهيلات الاستخدام",
    "fr": "Accessibilité",
    "pt": "Acessibilidade",
    "de": "Bedienungshilfen",
    "it": "Accessibilità"
  },
  "Read selected text in the source application.": {
    "en": "Read selected text in the source application.",
    "zh-Hans": "读取来源应用中选中的文本。",
    "hi": "मूल ऐप में चुना गया पाठ पढ़ें।",
    "es": "Leer el texto seleccionado en la aplicación de origen.",
    "ar": "قراءة النص المحدد في التطبيق المصدر.",
    "fr": "Lire le texte sélectionné dans l'application source.",
    "pt": "Ler o texto selecionado no aplicativo de origem.",
    "de": "Ausgewählten Text in der Quellanwendung lesen.",
    "it": "Leggi il testo selezionato nell'app di origine."
  },
  "No external services. If selected text is not directly accessible, MyEvent uses Copy and restores the clipboard.": {
    "en": "No external services. If selected text is not directly accessible, MyEvent uses Copy and restores the clipboard.",
    "zh-Hans": "不使用外部服务。如果无法直接读取选中文本，MyEvent会使用拷贝并恢复剪贴板。",
    "hi": "कोई बाहरी सेवा नहीं। पाठ सीधे न मिले तो MyEvent कॉपी करता है और क्लिपबोर्ड बहाल करता है।",
    "es": "Sin servicios externos. Si el texto no es accesible directamente, MyEvent usa Copiar y restaura el portapapeles.",
    "ar": "لا توجد خدمات خارجية. إذا تعذر الوصول المباشر للنص، يستخدم MyEvent النسخ ويستعيد الحافظة.",
    "fr": "Aucun service externe. Si la sélection est inaccessible directement, MyEvent utilise Copier et restaure le presse-papiers.",
    "pt": "Sem serviços externos. Se o texto não estiver acessível diretamente, o MyEvent usa Copiar e restaura a área de transferência.",
    "de": "Keine externen Dienste. Ist der ausgewählte Text nicht direkt zugänglich, verwendet MyEvent Kopieren und stellt die Zwischenablage wieder her.",
    "it": "Nessun servizio esterno. Se il testo selezionato non è accessibile direttamente, MyEvent usa Copia e ripristina gli appunti."
  },
  "Allowed": {
    "en": "Allowed",
    "zh-Hans": "已允许",
    "hi": "अनुमति है",
    "es": "Permitido",
    "ar": "مسموح",
    "fr": "Autorisé",
    "pt": "Permitido",
    "de": "Erlaubt",
    "it": "Consentito"
  },
  "Not allowed": {
    "en": "Not allowed",
    "zh-Hans": "未允许",
    "hi": "अनुमति नहीं है",
    "es": "No permitido",
    "ar": "غير مسموح",
    "fr": "À autoriser",
    "pt": "Não permitido",
    "de": "Nicht erlaubt",
    "it": "Non consentito"
  },
  "Allow…": {
    "en": "Allow…",
    "zh-Hans": "允许…",
    "hi": "अनुमति दें…",
    "es": "Permitir…",
    "ar": "السماح…",
    "fr": "Autoriser…",
    "pt": "Permitir…",
    "de": "Erlauben…",
    "it": "Consenti…"
  },
  "Created": {
    "en": "Created",
    "zh-Hans": "已创建",
    "hi": "बनाया गया",
    "es": "Creado",
    "ar": "تم الإنشاء",
    "fr": "Créé",
    "pt": "Criado",
    "de": "Erstellt",
    "it": "Creato"
  },
  "calendar(s)": {
    "en": "calendar(s)",
    "zh-Hans": "个日历",
    "hi": "कैलेंडर",
    "es": "calendario(s)",
    "ar": "تقويم",
    "fr": "calendrier(s)",
    "pt": "calendário(s)",
    "de": "Kalender",
    "it": "calendari"
  },
  "New event": {
    "en": "New event",
    "zh-Hans": "新日程",
    "hi": "नया इवेंट",
    "es": "Nuevo evento",
    "ar": "حدث جديد",
    "fr": "Nouvel événement",
    "pt": "Novo evento",
    "de": "Neuer Termin",
    "it": "Nuovo evento"
  },
  "This shortcut is already in use. Choose another combination in General.": {
    "en": "This shortcut is already in use. Choose another combination in General.",
    "zh-Hans": "此快捷键已被占用。请在常规中选择其他组合。",
    "hi": "यह शॉर्टकट पहले से उपयोग में है। सामान्य में दूसरा संयोजन चुनें।",
    "es": "Este atajo ya está en uso. Elige otra combinación en General.",
    "ar": "هذا الاختصار مستخدم بالفعل. اختر تركيبة أخرى في عام.",
    "fr": "Ce raccourci est déjà utilisé. Choisissez une autre combinaison dans Général.",
    "pt": "Este atalho já está em uso. Escolha outra combinação em Geral.",
    "de": "Dieses Tastenkürzel wird bereits verwendet. Wählen Sie unter Allgemein eine andere Kombination.",
    "it": "Questa scorciatoia è già in uso. Scegli un'altra combinazione in Generali."
  },
  "Calendar access denied. Allow full calendar access in System Settings.": {
    "en": "Calendar access denied. Allow full calendar access in System Settings.",
    "zh-Hans": "日历访问被拒绝。请在系统设置中允许完全访问日历。",
    "hi": "कैलेंडर पहुँच अस्वीकृत। सिस्टम सेटिंग्स में पूर्ण कैलेंडर पहुँच दें।",
    "es": "Acceso al calendario denegado. Permite el acceso completo en Ajustes del Sistema.",
    "ar": "تم رفض الوصول للتقويم. اسمح بالوصول الكامل في إعدادات النظام.",
    "fr": "Accès refusé. Autorisez l'accès complet aux calendriers dans Réglages Système.",
    "pt": "Acesso ao calendário negado. Permita acesso completo nos Ajustes do Sistema.",
    "de": "Kalenderzugriff verweigert. Erlauben Sie vollen Zugriff in den Systemeinstellungen.",
    "it": "Accesso ai calendari negato. Consenti l'accesso completo nelle Impostazioni di Sistema."
  },
  "Allow calendar access and select at least one available destination in Accounts.": {
    "en": "Allow calendar access and select at least one available destination in Accounts.",
    "zh-Hans": "允许访问日历，并在账户中选择至少一个可用目标。",
    "hi": "कैलेंडर पहुँच दें और खातों में कम से कम एक उपलब्ध गंतव्य चुनें।",
    "es": "Permite el acceso al calendario y selecciona al menos un destino disponible en Cuentas.",
    "ar": "اسمح بالوصول للتقويم وحدد وجهة متاحة واحدة على الأقل في الحسابات.",
    "fr": "Autorisez Calendriers et choisissez au moins une destination disponible dans Comptes.",
    "pt": "Permita acesso ao calendário e selecione ao menos um destino disponível em Contas.",
    "de": "Erlauben Sie Kalenderzugriff und wählen Sie unter Konten mindestens ein verfügbares Ziel.",
    "it": "Consenti l'accesso ai calendari e seleziona almeno una destinazione disponibile in Account."
  },
  "The selected text could not be turned into a valid event.": {
    "en": "The selected text could not be turned into a valid event.",
    "zh-Hans": "无法将选中文本转换为有效日程。",
    "hi": "चुने हुए पाठ से मान्य इवेंट नहीं बन सका।",
    "es": "No se pudo crear un evento válido a partir del texto seleccionado.",
    "ar": "تعذر إنشاء حدث صالح من النص المحدد.",
    "fr": "Le texte sélectionné ne permet pas de créer un événement valide.",
    "pt": "Não foi possível criar um evento válido com o texto selecionado.",
    "de": "Aus dem ausgewählten Text konnte kein gültiger Termin erstellt werden.",
    "it": "Impossibile creare un evento valido dal testo selezionato."
  },
  "Use ⌘, ⌥ or ⌃ with a key (⇧ alone is not enough).": {
    "en": "Use ⌘, ⌥ or ⌃ with a key (⇧ alone is not enough).",
    "zh-Hans": "请使用⌘、⌥或⌃加一个按键（仅⇧不够）。",
    "hi": "किसी कुंजी के साथ ⌘, ⌥ या ⌃ इस्तेमाल करें (केवल ⇧ पर्याप्त नहीं)।",
    "es": "Usa ⌘, ⌥ o ⌃ con una tecla (⇧ solo no basta).",
    "ar": "استخدم ⌘ أو ⌥ أو ⌃ مع مفتاح (⇧ وحده لا يكفي).",
    "fr": "Utilisez ⌘, ⌥ ou ⌃ avec une touche (⇧ seule ne suffit pas).",
    "pt": "Use ⌘, ⌥ ou ⌃ com uma tecla (apenas ⇧ não basta).",
    "de": "Verwenden Sie ⌘, ⌥ oder ⌃ mit einer Taste (⇧ allein reicht nicht).",
    "it": "Usa ⌘, ⌥ o ⌃ con un tasto (⇧ da solo non basta)."
  },
  "This combination is already in use. Try another, or press Escape to cancel.": {
    "en": "This combination is already in use. Try another, or press Escape to cancel.",
    "zh-Hans": "此组合已被占用。请尝试其他组合，或按Escape取消。",
    "hi": "यह संयोजन उपयोग में है। दूसरा आज़माएँ या रद्द करने के लिए Escape दबाएँ।",
    "es": "Esta combinación ya está en uso. Prueba otra o pulsa Escape para cancelar.",
    "ar": "هذه التركيبة مستخدمة. جرّب غيرها أو اضغط Escape للإلغاء.",
    "fr": "Cette combinaison est déjà utilisée. Essayez-en une autre, ou Échap pour annuler.",
    "pt": "Esta combinação já está em uso. Tente outra ou pressione Escape para cancelar.",
    "de": "Diese Kombination wird bereits verwendet. Versuchen Sie eine andere oder drücken Sie Escape zum Abbrechen.",
    "it": "Questa combinazione è già in uso. Provane un'altra o premi Esc per annullare."
  },
  "Shortcut unavailable. Choose another combination.": {
    "en": "Shortcut unavailable. Choose another combination.",
    "zh-Hans": "快捷键不可用。请选择其他组合。",
    "hi": "शॉर्टकट उपलब्ध नहीं। दूसरा संयोजन चुनें।",
    "es": "Atajo no disponible. Elige otra combinación.",
    "ar": "الاختصار غير متاح. اختر تركيبة أخرى.",
    "fr": "Raccourci indisponible. Choisissez une autre combinaison.",
    "pt": "Atalho indisponível. Escolha outra combinação.",
    "de": "Tastenkürzel nicht verfügbar. Wählen Sie eine andere Kombination.",
    "it": "Scorciatoia non disponibile. Scegli un'altra combinazione."
  },
  "Allow MyEvent in System Settings > Privacy & Security > Accessibility, then try the shortcut again.": {
    "en": "Allow MyEvent in System Settings > Privacy & Security > Accessibility, then try the shortcut again.",
    "zh-Hans": "请在系统设置 > 隐私与安全性 > 辅助功能中允许MyEvent，然后重试快捷键。",
    "hi": "सिस्टम सेटिंग्स > गोपनीयता और सुरक्षा > सुलभता में MyEvent को अनुमति दें, फिर शॉर्टकट आज़माएँ।",
    "es": "Permite MyEvent en Ajustes del Sistema > Privacidad y seguridad > Accesibilidad y vuelve a usar el atajo.",
    "ar": "اسمح لـ MyEvent في إعدادات النظام > الخصوصية والأمان > تسهيلات الاستخدام، ثم أعد تجربة الاختصار.",
    "fr": "Autorisez MyEvent dans Réglages Système > Confidentialité et sécurité > Accessibilité, puis réessayez le raccourci.",
    "pt": "Permita o MyEvent em Ajustes do Sistema > Privacidade e Segurança > Acessibilidade e tente o atalho novamente.",
    "de": "Erlauben Sie MyEvent unter Systemeinstellungen > Datenschutz & Sicherheit > Bedienungshilfen und versuchen Sie es erneut.",
    "it": "Autorizza MyEvent in Impostazioni di Sistema > Privacy e sicurezza > Accessibilità, poi riprova."
  },
  "No selected text is accessible. Select text in the source app, release the shortcut keys and try again.": {
    "en": "No selected text is accessible. Select text in the source app, release the shortcut keys and try again.",
    "zh-Hans": "无法读取选中文本。请在来源应用中选择文本，松开快捷键后重试。",
    "hi": "चुना हुआ पाठ उपलब्ध नहीं। मूल ऐप में पाठ चुनें, शॉर्टकट की कुंजियाँ छोड़ें और फिर कोशिश करें।",
    "es": "No se puede acceder al texto seleccionado. Selecciónalo en la app de origen, suelta las teclas y vuelve a intentarlo.",
    "ar": "تعذر الوصول للنص المحدد. حدد النص في التطبيق المصدر، واترك مفاتيح الاختصار ثم أعد المحاولة.",
    "fr": "Aucun texte sélectionné accessible. Sélectionnez le texte dans l'application source, relâchez les touches et réessayez.",
    "pt": "Não foi possível acessar o texto selecionado. Selecione o texto no app de origem, solte as teclas e tente novamente.",
    "de": "Kein ausgewählter Text zugänglich. Wählen Sie Text in der Quell-App, lassen Sie die Tasten los und versuchen Sie es erneut.",
    "it": "Il testo selezionato non è accessibile. Seleziona il testo nell'app di origine, rilascia i tasti e riprova."
  },
  "Quit": {
    "en": "Quit",
    "zh-Hans": "退出",
    "hi": "बंद करें",
    "es": "Salir",
    "ar": "إنهاء",
    "fr": "Quitter",
    "pt": "Sair",
    "de": "Beenden",
    "it": "Esci"
},
  "Hide": {
    "en": "Hide",
    "zh-Hans": "隐藏",
    "hi": "छिपाएँ",
    "es": "Ocultar",
    "ar": "إخفاء",
    "fr": "Masquer",
    "pt": "Ocultar",
    "de": "Ausblenden",
    "it": "Nascondi"
},
  "Hide MyEvent": {
    "en": "Hide MyEvent",
    "zh-Hans": "隐藏MyEvent",
    "hi": "MyEvent छिपाएँ",
    "es": "Ocultar MyEvent",
    "ar": "إخفاء MyEvent",
    "fr": "Masquer MyEvent",
    "pt": "Ocultar MyEvent",
    "de": "MyEvent ausblenden",
    "it": "Nascondi MyEvent"
  },
  "Show All": {
    "en": "Show All",
    "zh-Hans": "全部显示",
    "hi": "सभी दिखाएँ",
    "es": "Mostrar todo",
    "ar": "إظهار الكل",
    "fr": "Tout afficher",
    "pt": "Mostrar tudo",
    "de": "Alle einblenden",
    "it": "Mostra tutto"
  },
  "Quit MyEvent": {
    "en": "Quit MyEvent",
    "zh-Hans": "退出MyEvent",
    "hi": "MyEvent बंद करें",
    "es": "Salir de MyEvent",
    "ar": "إنهاء MyEvent",
    "fr": "Quitter MyEvent",
    "pt": "Sair do MyEvent",
    "de": "MyEvent beenden",
    "it": "Esci da MyEvent"
  },
  "Window": {
    "en": "Window",
    "zh-Hans": "窗口",
    "hi": "विंडो",
    "es": "Ventana",
    "ar": "النافذة",
    "fr": "Fenêtre",
    "pt": "Janela",
    "de": "Fenster",
    "it": "Finestra"
  },
  "Minimize": {
    "en": "Minimize",
    "zh-Hans": "最小化",
    "hi": "छोटा करें",
    "es": "Minimizar",
    "ar": "تصغير",
    "fr": "Réduire",
    "pt": "Minimizar",
    "de": "Minimieren",
    "it": "Contrai"
  },
  "Close": {
    "en": "Close",
    "zh-Hans": "关闭",
    "hi": "बंद करें",
    "es": "Cerrar",
    "ar": "إغلاق",
    "fr": "Fermer",
    "pt": "Fechar",
    "de": "Schließen",
    "it": "Chiudi"
  },
  "Bring All to Front": {
    "en": "Bring All to Front",
    "zh-Hans": "全部置于前方",
    "hi": "सभी सामने लाएँ",
    "es": "Traer todo al frente",
    "ar": "إحضار الكل إلى المقدمة",
    "fr": "Tout ramener au premier plan",
    "pt": "Trazer tudo para frente",
    "de": "Alle nach vorne bringen",
    "it": "Porta tutto in primo piano"
  },
  "Help": {
    "en": "Help",
    "zh-Hans": "帮助",
    "hi": "सहायता",
    "es": "Ayuda",
    "ar": "المساعدة",
    "fr": "Aide",
    "pt": "Ajuda",
    "de": "Hilfe",
    "it": "Aiuto"
  },
  "MyEvent lists your calendars so you can choose destinations and immediately add events using your shortcut.": {
    "en": "MyEvent lists your calendars so you can choose destinations and immediately add events using your shortcut.",
    "zh-Hans": "MyEvent列出您的日历，以便您选择目标并使用快捷键立即添加日程。",
    "hi": "MyEvent आपके कैलेंडर दिखाता है ताकि आप गंतव्य चुनें और शॉर्टकट से तुरंत इवेंट जोड़ें।",
    "es": "MyEvent muestra tus calendarios para elegir destinos y añadir eventos al instante con el atajo.",
    "ar": "يعرض MyEvent تقاويمك لاختيار الوجهات وإضافة الأحداث فورًا باستخدام الاختصار.",
    "fr": "MyEvent affiche vos calendriers pour choisir les destinations et ajouter immédiatement les événements avec votre raccourci.",
    "pt": "O MyEvent lista seus calendários para escolher destinos e adicionar eventos imediatamente com o atalho.",
    "de": "MyEvent zeigt Ihre Kalender an, damit Sie Ziele auswählen und mit dem Tastenkürzel sofort Termine hinzufügen können.",
    "it": "MyEvent elenca i calendari per scegliere le destinazioni e aggiungere subito eventi con la scorciatoia."
  },
  "MyEvent adds events to the calendars you select when you use the shortcut.": {
    "en": "MyEvent adds events to the calendars you select when you use the shortcut.",
    "zh-Hans": "使用快捷键时，MyEvent会将日程添加到您选择的日历。",
    "hi": "शॉर्टकट इस्तेमाल करने पर MyEvent चुने हुए कैलेंडर में इवेंट जोड़ता है।",
    "es": "MyEvent añade eventos a los calendarios que selecciones al usar el atajo.",
    "ar": "يضيف MyEvent الأحداث إلى التقاويم المحددة عند استخدام الاختصار.",
    "fr": "MyEvent ajoute les événements dans les calendriers sélectionnés lorsque vous utilisez le raccourci.",
    "pt": "O MyEvent adiciona eventos aos calendários selecionados quando você usa o atalho.",
    "de": "MyEvent fügt Termine zu den ausgewählten Kalendern hinzu, wenn Sie das Tastenkürzel verwenden.",
    "it": "MyEvent aggiunge eventi ai calendari selezionati quando usi la scorciatoia."
  },
  "Build": {
    "en": "Build",
    "zh-Hans": "构建",
    "hi": "बिल्ड",
    "es": "Compilación",
    "ar": "الإصدار البرمجي",
    "fr": "Build",
    "pt": "Compilação",
    "de": "Build",
    "it": "Build"
  },
  "Details": {
    "en": "Details",
    "zh-Hans": "详情",
    "hi": "विवरण",
    "es": "Detalles",
    "ar": "التفاصيل",
    "fr": "Détails",
    "pt": "Detalhes",
    "de": "Details",
    "it": "Dettagli"
  },
  "Participants": {
    "en": "Participants",
    "zh-Hans": "参与者",
    "hi": "प्रतिभागी",
    "es": "Participantes",
    "ar": "المشاركون",
    "fr": "Participants",
    "pt": "Participantes",
    "de": "Teilnehmer",
    "it": "Partecipanti"
  },
  "Links": {
    "en": "Links",
    "zh-Hans": "链接",
    "hi": "लिंक",
    "es": "Enlaces",
    "ar": "الروابط",
    "fr": "Liens",
    "pt": "Links",
    "de": "Links",
    "it": "Collegamenti"
  },
  "Location": {
    "en": "Location",
    "zh-Hans": "地点",
    "hi": "स्थान",
    "es": "Lugar",
    "ar": "الموقع",
    "fr": "Lieu",
    "pt": "Local",
    "de": "Ort",
    "it": "Luogo"
  },
  "Start": {
    "en": "Start",
    "zh-Hans": "开始",
    "hi": "शुरू",
    "es": "Inicio",
    "ar": "البداية",
    "fr": "Début",
    "pt": "Início",
    "de": "Beginn",
    "it": "Inizio"
  },
  "End": {
    "en": "End",
    "zh-Hans": "结束",
    "hi": "समाप्ति",
    "es": "Fin",
    "ar": "النهاية",
    "fr": "Fin",
    "pt": "Fim",
    "de": "Ende",
    "it": "Fine"
  },
  "The chosen language is used for the event title and detailed notes.": {
    "en": "The chosen language is used for the event title and detailed notes.",
    "zh-Hans": "所选语言用于日程标题和详细备注。",
    "hi": "चुनी भाषा इवेंट शीर्षक और विस्तृत नोट्स में इस्तेमाल होगी।",
    "es": "El idioma elegido se usa en el título y las notas del evento.",
    "ar": "تُستخدم اللغة المختارة لعنوان الحدث وملاحظاته التفصيلية.",
    "fr": "La langue choisie s'applique au titre et aux notes détaillées de l'événement.",
    "pt": "O idioma escolhido é usado no título e nas notas detalhadas.",
    "de": "Die gewählte Sprache gilt für Titel und ausführliche Notizen des Termins.",
    "it": "La lingua scelta viene usata per il titolo e le note dettagliate dell'evento."
  },
  "Translation is unavailable for this language pair on this Mac. No event was created.": {
    "en": "Translation is unavailable for this language pair on this Mac. No event was created.",
    "zh-Hans": "此Mac不支持该语言对的翻译，未创建日程。",
    "hi": "इस Mac पर इन भाषाओं का अनुवाद उपलब्ध नहीं है। कोई इवेंट नहीं बना।",
    "es": "Esta traducción no está disponible en este Mac. No se ha creado ningún evento.",
    "ar": "الترجمة غير متاحة لهاتين اللغتين على هذا Mac. لم يُنشأ أي حدث.",
    "fr": "Cette traduction n'est pas disponible sur ce Mac. Aucun événement n'a été créé.",
    "pt": "Esta tradução não está disponível neste Mac. Nenhum evento foi criado.",
    "de": "Dieses Sprachpaar wird auf diesem Mac nicht unterstützt. Es wurde kein Termin erstellt.",
    "it": "Questa traduzione non è disponibile su questo Mac. Nessun evento è stato creato."
  },
  "Automatic translation requires macOS 26 or later. No event was created.": {
    "en": "Automatic translation requires macOS 26 or later. No event was created.",
    "zh-Hans": "自动翻译需要macOS 26或更高版本。未创建日程。",
    "hi": "स्वचालित अनुवाद के लिए macOS 26 या बाद का संस्करण चाहिए। कोई इवेंट नहीं बना।",
    "es": "La traducción automática requiere macOS 26 o posterior. No se ha creado ningún evento.",
    "ar": "تتطلب الترجمة التلقائية macOS 26 أو أحدث. لم يُنشأ أي حدث.",
    "fr": "La traduction automatique nécessite macOS 26 ou ultérieur. Aucun événement n'a été créé.",
    "pt": "A tradução automática exige macOS 26 ou posterior. Nenhum evento foi criado.",
    "de": "Automatische Übersetzung erfordert macOS 26 oder neuer. Es wurde kein Termin erstellt.",
    "it": "La traduzione automatica richiede macOS 26 o successivo. Nessun evento è stato creato."
  },
  "The source language could not be identified. Select a longer text and try again.": {
    "en": "The source language could not be identified. Select a longer text and try again.",
    "zh-Hans": "无法识别源语言。请选择更长的文本后重试。",
    "hi": "मूल भाषा पहचानी नहीं गई। लंबा पाठ चुनकर फिर कोशिश करें।",
    "es": "No se pudo identificar el idioma. Selecciona un texto más largo e inténtalo de nuevo.",
    "ar": "تعذر تحديد لغة المصدر. حدد نصًا أطول وأعد المحاولة.",
    "fr": "La langue source n'a pas pu être identifiée. Sélectionnez un texte plus long et réessayez.",
    "pt": "Não foi possível identificar o idioma. Selecione um texto mais longo e tente novamente.",
    "de": "Die Ausgangssprache wurde nicht erkannt. Wählen Sie einen längeren Text und versuchen Sie es erneut.",
    "it": "Impossibile identificare la lingua. Seleziona un testo più lungo e riprova."
  },
  "Translating event text…": {
    "en": "Translating event text…",
    "zh-Hans": "正在翻译日程文本…",
    "hi": "इवेंट के पाठ का अनुवाद हो रहा है…",
    "es": "Traduciendo el texto del evento…",
    "ar": "جارٍ ترجمة نص الحدث…",
    "fr": "Traduction du texte de l'événement…",
    "pt": "Traduzindo o texto do evento…",
    "de": "Termintext wird übersetzt…",
    "it": "Traduzione del testo dell'evento…"
},
  "Translation failed. No event was created.": {
    "en": "Translation failed. No event was created.",
    "zh-Hans": "翻译失败。未创建日程。",
    "hi": "अनुवाद विफल। कोई इवेंट नहीं बना।",
    "es": "La traducción falló. No se ha creado ningún evento.",
    "ar": "فشلت الترجمة. لم يُنشأ أي حدث.",
    "fr": "La traduction a échoué. Aucun événement n'a été créé.",
    "pt": "A tradução falhou. Nenhum evento foi criado.",
    "de": "Übersetzung fehlgeschlagen. Es wurde kein Termin erstellt.",
    "it": "Traduzione non riuscita. Nessun evento è stato creato."
  },
  "Install translation languages in System Settings > General > Language & Region > Translation Languages, then try again. No event was created.": {
    "en": "Install translation languages in System Settings > General > Language & Region > Translation Languages, then try again. No event was created.",
    "zh-Hans": "请在系统设置 > 通用 > 语言与地区 > 翻译语言中安装语言，然后重试。未创建日程。",
    "hi": "सिस्टम सेटिंग्स > सामान्य > भाषा और क्षेत्र > अनुवाद भाषाएँ में भाषाएँ इंस्टॉल करें और फिर कोशिश करें। कोई इवेंट नहीं बना।",
    "es": "Instala los idiomas en Ajustes del Sistema > General > Idioma y región > Idiomas de traducción y vuelve a intentarlo. No se ha creado ningún evento.",
    "ar": "ثبّت لغات الترجمة في إعدادات النظام > عام > اللغة والمنطقة > لغات الترجمة، ثم أعد المحاولة. لم يُنشأ أي حدث.",
    "fr": "Installez les langues dans Réglages Système > Général > Langue et région > Langues de traduction, puis réessayez. Aucun événement créé.",
    "pt": "Instale os idiomas em Ajustes do Sistema > Geral > Idioma e Região > Idiomas de Tradução e tente novamente. Nenhum evento foi criado.",
    "de": "Installieren Sie die Sprachen unter Systemeinstellungen > Allgemein > Sprache & Region > Übersetzungssprachen und versuchen Sie es erneut. Es wurde kein Termin erstellt.",
    "it": "Installa le lingue in Impostazioni di Sistema > Generali > Lingua e zona > Lingue di traduzione e riprova. Nessun evento è stato creato."
  },
  "If MyEvent is already enabled in macOS, remove the old entry, add this app again, then quit and reopen MyEvent.": {
    "en": "If MyEvent is already enabled in macOS, remove the old entry, add this app again, then quit and reopen MyEvent.",
    "zh-Hans": "如果macOS中已启用MyEvent，请移除旧条目，重新添加此应用，然后退出并重新打开MyEvent。",
    "hi": "यदि macOS में MyEvent पहले से सक्षम है, तो पुरानी प्रविष्टि हटाएँ, इस ऐप को फिर जोड़ें और MyEvent बंद करके दोबारा खोलें।",
    "es": "Si MyEvent ya está activado en macOS, elimina la entrada antigua, añade esta app de nuevo y reinicia MyEvent.",
    "ar": "إذا كان MyEvent مفعّلًا بالفعل في macOS، فأزل الإدخال القديم وأضف هذا التطبيق مجددًا، ثم أغلق MyEvent وأعد فتحه.",
    "fr": "Si MyEvent est déjà activé dans macOS, supprimez l'ancienne entrée, ajoutez cette application, puis quittez et rouvrez MyEvent.",
    "pt": "Se o MyEvent já estiver ativado no macOS, remova a entrada antiga, adicione este app novamente e reinicie o MyEvent.",
    "de": "Wenn MyEvent in macOS bereits aktiviert ist, entfernen Sie den alten Eintrag, fügen Sie diese App erneut hinzu und starten Sie MyEvent neu.",
    "it": "Se MyEvent è già abilitato in macOS, rimuovi la vecchia voce, aggiungi di nuovo questa app, poi chiudi e riapri MyEvent."
  },
  "The red button quits MyEvent and disables the shortcut. The yellow button minimizes the window and keeps MyEvent running.": {
    "en": "The red button quits MyEvent and disables the shortcut. The yellow button minimizes the window and keeps MyEvent running.",
    "zh-Hans": "红色按钮退出MyEvent并停用快捷键。黄色按钮最小化窗口并保持MyEvent运行。",
    "hi": "लाल बटन MyEvent बंद कर देता है और शॉर्टकट निष्क्रिय करता है। पीला बटन विंडो छोटा करता है और MyEvent चालू रखता है।",
    "es": "El botón rojo cierra MyEvent y desactiva el atajo. El amarillo minimiza la ventana y mantiene MyEvent activo.",
    "ar": "الزر الأحمر ينهي MyEvent ويعطل الاختصار. الزر الأصفر يصغر النافذة ويبقي MyEvent قيد التشغيل.",
    "fr": "Le bouton rouge quitte MyEvent et désactive le raccourci. Le bouton jaune réduit la fenêtre et laisse MyEvent actif.",
    "pt": "O botão vermelho encerra o MyEvent e desativa o atalho. O amarelo minimiza a janela e mantém o MyEvent ativo.",
    "de": "Die rote Taste beendet MyEvent und deaktiviert das Tastenkürzel. Die gelbe Taste minimiert das Fenster und lässt MyEvent aktiv.",
    "it": "Il pulsante rosso chiude MyEvent e disattiva la scorciatoia. Quello giallo riduce la finestra e mantiene MyEvent attivo."
  },
  "Event created": {
    "en": "Event created",
    "zh-Hans": "日程已创建",
    "hi": "इवेंट बन गया",
    "es": "Evento creado",
    "ar": "تم إنشاء الحدث",
    "fr": "Événement créé",
    "pt": "Evento criado",
    "de": "Termin erstellt",
    "it": "Evento creato"
  },
  "Event creation failed": {
    "en": "Event creation failed",
    "zh-Hans": "日程创建失败",
    "hi": "इवेंट नहीं बना",
    "es": "Error al crear el evento",
    "ar": "تعذر إنشاء الحدث",
    "fr": "Échec de création de l'événement",
    "pt": "Falha ao criar o evento",
    "de": "Termin konnte nicht erstellt werden",
    "it": "Creazione dell'evento non riuscita"
  },
  "Review event": {
    "en": "Review event",
    "zh-Hans": "检查日程",
    "hi": "इवेंट की समीक्षा करें",
    "es": "Revisar evento",
    "ar": "مراجعة الحدث",
    "fr": "Vérifier l'événement",
    "pt": "Rever evento",
    "de": "Termin prüfen",
    "it": "Rivedi evento"
  },
  "Title": {
    "en": "Title",
    "zh-Hans": "标题",
    "hi": "शीर्षक",
    "es": "Título",
    "ar": "العنوان",
    "fr": "Titre",
    "pt": "Título",
    "de": "Titel",
    "it": "Titolo"
  },
  "Notes": {
    "en": "Notes",
    "zh-Hans": "备注",
    "hi": "नोट्स",
    "es": "Notas",
    "ar": "الملاحظات",
    "fr": "Notes",
    "pt": "Notas",
    "de": "Notizen",
    "it": "Note"
  },
  "Link": {
    "en": "Link",
    "zh-Hans": "链接",
    "hi": "लिंक",
    "es": "Enlace",
    "ar": "الرابط",
    "fr": "Lien",
    "pt": "Link",
    "de": "Link",
    "it": "Link"
  },
  "Create event": {
    "en": "Create event",
    "zh-Hans": "创建日程",
    "hi": "इवेंट बनाएँ",
    "es": "Crear evento",
    "ar": "إنشاء الحدث",
    "fr": "Créer l'événement",
    "pt": "Criar evento",
    "de": "Termin erstellen",
    "it": "Crea evento"
  },
  "Enter an event title.": {
    "en": "Enter an event title.",
    "zh-Hans": "请输入日程标题。",
    "hi": "इवेंट का शीर्षक दर्ज करें।",
    "es": "Introduce un título para el evento.",
    "ar": "أدخل عنوان الحدث.",
    "fr": "Saisissez un titre pour l'événement.",
    "pt": "Introduza um título para o evento.",
    "de": "Geben Sie einen Titel ein.",
    "it": "Inserisci un titolo per l'evento."
  },
  "The end must be after the start.": {
    "en": "The end must be after the start.",
    "zh-Hans": "结束时间必须晚于开始时间。",
    "hi": "समाप्ति का समय प्रारंभ के बाद होना चाहिए।",
    "es": "El final debe ser posterior al inicio.",
    "ar": "يجب أن تكون النهاية بعد البداية.",
    "fr": "La fin doit être après le début.",
    "pt": "O fim deve ser posterior ao início.",
    "de": "Das Ende muss nach dem Beginn liegen.",
    "it": "La fine deve essere successiva all'inizio."
  },
  "Enter a valid http or https link.": {
    "en": "Enter a valid http or https link.",
    "zh-Hans": "请输入有效的 http 或 https 链接。",
    "hi": "एक मान्य http या https लिंक दर्ज करें।",
    "es": "Introduce un enlace http o https válido.",
    "ar": "أدخل رابط http أو https صالحًا.",
    "fr": "Saisissez un lien http ou https valide.",
    "pt": "Introduza um link http ou https válido.",
    "de": "Geben Sie einen gültigen http- oder https-Link ein.",
    "it": "Inserisci un link http o https valido."
  },
  "Review the details, then confirm to create the event.": {
    "en": "Review the details, then confirm to create the event.",
    "zh-Hans": "请检查详细信息，然后确认创建日程。",
    "hi": "विवरण की समीक्षा करें, फिर इवेंट बनाने के लिए पुष्टि करें।",
    "es": "Revisa los detalles y confirma para crear el evento.",
    "ar": "راجع التفاصيل، ثم أكد لإنشاء الحدث.",
    "fr": "Vérifiez les détails, puis confirmez la création de l'événement.",
    "pt": "Reveja os detalhes e confirme para criar o evento.",
    "de": "Prüfen Sie die Details und bestätigen Sie die Erstellung des Termins.",
    "it": "Verifica i dettagli, poi conferma per creare l'evento."
  },
  "Select text and press the shortcut. Review the details before creating the event.": {
    "en": "Select text and press the shortcut. Review the details before creating the event.",
    "zh-Hans": "选择文本并按快捷键。创建日程前请检查详细信息。",
    "hi": "टेक्स्ट चुनें और शॉर्टकट दबाएँ। इवेंट बनाने से पहले विवरण की समीक्षा करें।",
    "es": "Selecciona texto y pulsa el atajo. Revisa los detalles antes de crear el evento.",
    "ar": "حدد النص واضغط الاختصار. راجع التفاصيل قبل إنشاء الحدث.",
    "fr": "Sélectionnez du texte et utilisez le raccourci. Vérifiez les détails avant de créer l'événement.",
    "pt": "Selecione texto e prima o atalho. Reveja os detalhes antes de criar o evento.",
    "de": "Markieren Sie Text und drücken Sie das Tastenkürzel. Prüfen Sie die Details vor der Erstellung.",
    "it": "Seleziona il testo e premi la scorciatoia. Verifica i dettagli prima di creare l'evento."
  },
  "Preparing event…": {
    "en": "Preparing event…",
    "zh-Hans": "正在准备日程…",
    "hi": "इवेंट तैयार हो रहा है…",
    "es": "Preparando evento…",
    "ar": "جارٍ تحضير الحدث…",
    "fr": "Préparation de l'événement…",
    "pt": "A preparar evento…",
    "de": "Termin wird vorbereitet…",
    "it": "Preparazione dell'evento…"
  }
}
"""#
        return try! JSONDecoder().decode([String: [String: String]].self, from: Data(json.utf8))
    }()
}

/// The stable application identifier intentionally remains unchanged across the rename.
enum PreferencesMigration {
    static func run() {
        UserDefaults.standard.removeObject(forKey: "durationMinutes")
        UserDefaults.standard.removeObject(forKey: "defaultHour")
        UserDefaults.standard.removeObject(forKey: "calendarApplication")
        UserDefaults.standard.removeObject(forKey: "playSound")
        UserDefaults.standard.removeObject(forKey: "creationSound")
        guard UserDefaults.standard.object(forKey: "interfaceLanguage") == nil else { return }
        UserDefaults.standard.set("en", forKey: "interfaceLanguage")
    }
}
