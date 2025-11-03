import 'package:get/get.dart';

class LanguageController extends GetxController {
  var selectedLanguage = "English".obs; // Set English as default
  var selectedCategory = "".obs;

  final List<String> languages = [
    "English",
    "Arabic",
    "French",
    "Chinese",
    "Urdu",
  ];

  final List<String> categories = [
    "Learn NFT's",
    "Learn Crypto",
    "Learn Blockchain",
    "Learn Mining",
    "Learn Stock Market",
  ];

  // Translation maps for each language
  final Map<String, Map<String, String>> translations = {
    "English": {
      "language": "Language",
      "back": "Back",
      "upload_an_add": "Upload An Add",
      "learn_nfts": "Learn NFT's",
      "learn_crypto": "Learn Crypto",
      "learn_blockchain": "Learn Blockchain",
      "learn_mining": "Learn Mining",
      "learn_stock_market": "Learn Stock Market",
      "earn_koins_daily": "Earn 10 ZRK Daily By Learning!",
      "timer": "Timer",
      "previous": "Previous",
      "next": "Next",
      "no_content_available": "No content available for this course.",
      "select_a_course": "Please select a course to view its content.",
      "zerokoin_content":
          "Learning Zerokoin opens the door to understanding enhanced privacy in cryptocurrency transactions. It is a protocol designed to improve anonymity by hiding users' transaction histories.\n\n"
          "Zerokoin introduces a system where coins can be minted and later spent without linking the two actions, breaking the traceable chain. Studying it helps you grasp important cryptographic concepts like zero-knowledge proofs.\n\n"
          "The protocol works by allowing users to convert their bitcoins into zerocoins, which are then stored in an accumulator. When spending, users can redeem any zerocoin from the accumulator without revealing which specific zerocoin they originally deposited.\n\n"
          "This process involves complex mathematical proofs that demonstrate ownership without revealing identity. The zero-knowledge proof system ensures that while the transaction is valid, the link between the spender and the original coin is completely broken.\n\n"
          "Understanding Zerokoin is crucial for anyone interested in privacy-focused cryptocurrencies. It laid the groundwork for many modern privacy coins and continues to influence the development of anonymous transaction systems.\n\n"
          "The mathematical foundations include commitment schemes, accumulators, and zero-knowledge proofs of knowledge. These concepts are fundamental to modern cryptography and have applications beyond just cryptocurrency.\n\n"
          "By studying Zerokoin, you'll gain insights into how privacy can be achieved in public blockchain systems, the trade-offs between transparency and anonymity, and the computational challenges involved in implementing such systems.\n\n"
          "This knowledge is essential for blockchain developers, security researchers, and anyone working on privacy-preserving technologies in the digital age.",
    },
    "Arabic": {
      "language": "اللغة",
      "back": "رجوع",
      "upload_an_add": "رفع إعلان",
      "learn_nfts": "تعلم الرموز غير القابلة للاستبدال",
      "learn_crypto": "تعلم العملات المشفرة",
      "learn_blockchain": "تعلم البلوك تشين",
      "learn_mining": "تعلم التعدين",
      "learn_stock_market": "تعلم سوق الأسهم",
      "earn_koins_daily": "اكسب 10 عملات كوين يومياً من خلال التعلم!",
      "timer": "المؤقت",
      "previous": "السابق",
      "next": "التالي",
      "no_content_available": "لا يوجد محتوى متاح لهذه الدورة.",
      "select_a_course": "الرجاء اختيار دورة لعرض محتواها.",
      "zerokoin_content":
          "تعلم زيروكوين يفتح الباب لفهم الخصوصية المحسنة في معاملات العملات المشفرة. إنه بروتوكول مصمم لتحسين إخفاء الهوية عن طريق إخفاء تاريخ معاملات المستخدمين.\n\n"
          "يقدم زيروكوين نظاماً حيث يمكن سك العملات وإنفاقها لاحقاً دون ربط الإجراءين، مما يكسر السلسلة القابلة للتتبع. دراسته تساعدك على فهم المفاهيم المشفرة المهمة مثل إثباتات المعرفة الصفرية.\n\n"
          "يعمل البروتوكول من خلال السماح للمستخدمين بتحويل عملاتهم البيتكوين إلى زيروكوين، والتي يتم تخزينها بعد ذلك في مجمع. عند الإنفاق، يمكن للمستخدمين استرداد أي زيروكوين من المجمع دون الكشف عن الزيروكوين المحدد الذي أودعوه في الأصل.\n\n"
          "تتضمن هذه العملية إثباتات رياضية معقدة تثبت الملكية دون الكشف عن الهوية. يضمن نظام إثبات المعرفة الصفرية أنه بينما المعاملة صالحة، فإن الرابط بين المنفق والعملة الأصلية مكسور تماماً.\n\n"
          "فهم زيروكوين أمر بالغ الأهمية لأي شخص مهتم بالعملات المشفرة التي تركز على الخصوصية. لقد وضع الأساس للعديد من عملات الخصوصية الحديثة ويستمر في التأثير على تطوير أنظمة المعاملات المجهولة.\n\n"
          "تشمل الأسس الرياضية مخططات الالتزام والمجمعات وإثباتات المعرفة الصفرية. هذه المفاهيم أساسية للتشفير الحديث ولها تطبيقات تتجاوز العملة المشفرة فقط.\n\n"
          "من خلال دراسة زيروكوين، ستحصل على رؤى حول كيفية تحقيق الخصوصية في أنظمة البلوك تشين العامة، والمقايضات بين الشفافية وإخفاء الهوية، والتحديات الحاسوبية المتضمنة في تنفيذ مثل هذه الأنظمة.\n\n"
          "هذه المعرفة ضرورية لمطوري البلوك تشين وباحثي الأمان وأي شخص يعمل على تقنيات الحفاظ على الخصوصية في العصر الرقمي.",
    },
    "French": {
      "language": "Langue",
      "back": "Retour",
      "upload_an_add": "Télécharger une Annonce",
      "learn_nfts": "Apprendre les NFT",
      "learn_crypto": "Apprendre la Crypto",
      "learn_blockchain": "Apprendre la Blockchain",
      "learn_mining": "Apprendre le Minage",
      "learn_stock_market": "Apprendre la Bourse",
      "earn_koins_daily": "Gagnez 10 Koins par Jour en Apprenant!",
      "timer": "Minuteur",
      "previous": "Précédent",
      "next": "Suivant",
      "no_content_available": "Aucun contenu disponible pour ce cours.",
      "select_a_course":
          "Veuillez sélectionner un cours pour voir son contenu.",
      "zerokoin_content":
          "Apprendre Zerocoin ouvre la porte à la compréhension de la confidentialité améliorée dans les transactions de cryptomonnaies. C'est un protocole conçu pour améliorer l'anonymat en cachant l'historique des transactions des utilisateurs.\n\n"
          "Zerocoin introduit un système où les pièces peuvent être frappées et dépensées plus tard sans lier les deux actions, brisant la chaîne traçable. L'étudier vous aide à saisir des concepts cryptographiques importants comme les preuves à divulgation nulle de connaissance.\n\n"
          "Le protocole fonctionne en permettant aux utilisateurs de convertir leurs bitcoins en zerocoins, qui sont ensuite stockés dans un accumulateur. Lors des dépenses, les utilisateurs peuvent racheter n'importe quel zerocoin de l'accumulateur sans révéler quel zerocoin spécifique ils ont déposé à l'origine.\n\n"
          "Ce processus implique des preuves mathématiques complexes qui démontrent la propriété sans révéler l'identité. Le système de preuve à divulgation nulle de connaissance garantit que bien que la transaction soit valide, le lien entre le dépensier et la pièce originale est complètement brisé.\n\n"
          "Comprendre Zerocoin est crucial pour quiconque s'intéresse aux cryptomonnaies axées sur la confidentialité. Il a jeté les bases de nombreuses pièces de confidentialité modernes et continue d'influencer le développement de systèmes de transactions anonymes.\n\n"
          "Les fondements mathématiques incluent les schémas d'engagement, les accumulateurs et les preuves à divulgation nulle de connaissance. Ces concepts sont fondamentaux pour la cryptographie moderne et ont des applications au-delà de la cryptomonnaie.\n\n"
          "En étudiant Zerocoin, vous obtiendrez des aperçus sur la façon dont la confidentialité peut être atteinte dans les systèmes de blockchain publics, les compromis entre transparence et anonymat, et les défis computationnels impliqués dans la mise en œuvre de tels systèmes.\n\n"
          "Cette connaissance est essentielle pour les développeurs de blockchain, les chercheurs en sécurité et quiconque travaille sur des technologies de préservation de la confidentialité à l'ère numérique.",
    },
    "Chinese": {
      "language": "语言",
      "back": "返回",
      "upload_an_add": "上传广告",
      "learn_nfts": "学习NFT",
      "learn_crypto": "学习加密货币",
      "learn_blockchain": "学习区块链",
      "learn_mining": "学习挖矿",
      "learn_stock_market": "学习股票市场",
      "earn_koins_daily": "每天学习赚取10个Koin！",
      "timer": "计时器",
      "previous": "上一页",
      "next": "下一页",
      "no_content_available": "此课程没有可用内容。",
      "select_a_course": "请选择一个课程以查看其内容。",
      "zerokoin_content":
          "学习Zerocoin为理解加密货币交易中的增强隐私打开了大门。这是一个旨在通过隐藏用户交易历史来改善匿名性的协议。\n\n"
          "Zerocoin引入了一个系统，其中硬币可以被铸造并在以后花费，而不链接这两个动作，打破了可追踪的链条。研究它有助于您掌握重要的密码学概念，如零知识证明。\n\n"
          "该协议通过允许用户将他们的比特币转换为zerocoins来工作，然后将其存储在累加器中。在花费时，用户可以从累加器中赎回任何zerocoin，而不透露他们最初存入的特定zerocoin。\n\n"
          "这个过程涉及复杂的数学证明，证明所有权而不透露身份。零知识证明系统确保虽然交易是有效的，但花费者和原始硬币之间的链接完全断开。\n\n"
          "理解Zerocoin对于任何对注重隐私的加密货币感兴趣的人来说都是至关重要的。它为许多现代隐私币奠定了基础，并继续影响匿名交易系统的发展。\n\n"
          "数学基础包括承诺方案、累加器和零知识证明。这些概念是现代密码学的基础，其应用超越了加密货币。\n\n"
          "通过研究Zerocoin，您将深入了解如何在公共区块链系统中实现隐私，透明度和匿名性之间的权衡，以及实施此类系统所涉及的计算挑战。\n\n"
          "这些知识对于区块链开发人员、安全研究人员以及任何在数字时代从事隐私保护技术工作的人来说都是必不可少的。",
    },
    "Urdu": {
      "language": "زبان",
      "back": "واپس",
      "upload_an_add": "اشتہار اپ لوڈ کریں",
      "learn_nfts": "NFTs سیکھیں",
      "learn_crypto": "کرپٹو سیکھیں",
      "learn_blockchain": "بلاک چین سیکھیں",
      "learn_mining": "مائننگ سیکھیں",
      "learn_stock_market": "اسٹاک مارکیٹ سیکھیں",
      "earn_koins_daily": "سیکھ کر روزانہ 10 کوائن کمائیں!",
      "timer": "ٹائمر",
      "previous": "پچھلا",
      "next": "اگلا",
      "no_content_available": "اس کورس کے لیے کوئی مواد دستیاب نہیں ہے۔",
      "select_a_course": "مواد دیکھنے کے لیے براہ کرم ایک کورس منتخب کریں۔",
      "zerokoin_content":
          "زیروکوائن سیکھنا کرپٹو کرنسی لین دین میں بہتر پرائیویسی کو سمجھنے کا دروازہ کھولتا ہے۔ یہ ایک پروٹوکول ہے جو صارفین کی لین دین کی تاریخ چھپا کر گمنامی کو بہتر بنانے کے لیے ڈیزائن کیا گیا ہے۔\n\n"
          "زیروکوائن ایک ایسا نظام متعارف کراتا ہے جہاں سکے بنائے جا سکتے ہیں اور بعد میں خرچ کیے جا سکتے ہیں دونوں اعمال کو جوڑے بغیر، قابل تعاقب زنجیر کو توڑتے ہوئے۔ اس کا مطالعہ آپ کو اہم کرپٹوگرافک تصورات جیسے زیرو نالج پروفز کو سمجھنے میں مدد کرتا ہے۔\n\n"
          "یہ پروٹوکول صارفین کو اپنے بٹ کوائن کو زیروکوائن میں تبدیل کرنے کی اجازت دے کر کام کرتا ہے، جو پھر ایک ایکومولیٹر میں محفوظ کیے جاتے ہیں۔ خرچ کرتے وقت، صارفین ایکومولیٹر سے کوئی بھی زیروکوائن چھڑا سکتے ہیں اس بات کو ظاہر کیے بغیر کہ انہوں نے اصل میں کون سا مخصوص زیروکوائن جمع کیا تھا۔\n\n"
          "اس عمل میں پیچیدہ ریاضی کے ثبوت شامل ہیں جو شناخت ظاہر کیے بغیر ملکیت کا ثبوت دیتے ہیں۔ زیرو نالج پروف سسٹم اس بات کو یقینی بناتا ہے کہ جبکہ لین دین درست ہے، خرچ کرنے والے اور اصل سکے کے درمیان رابطہ مکمل طور پر ٹوٹ جاتا ہے۔\n\n"
          "زیروکوائن کو سمجھنا پرائیویسی پر مرکوز کرپٹو کرنسیوں میں دلچسپی رکھنے والے کسی بھی شخص کے لیے انتہائی اہم ہے۔ اس نے بہت سے جدید پرائیویسی کوائنز کی بنیاد رکھی ہے اور گمنام لین دین کے نظام کی ترقی پر اثر انداز ہونا جاری رکھا ہے۔\n\n"
          "ریاضی کی بنیادوں میں کمٹمنٹ اسکیمز، ایکومولیٹرز، اور زیرو نالج پروفز آف نالج شامل ہیں۔ یہ تصورات جدید کرپٹوگرافی کے لیے بنیادی ہیں اور کرپٹو کرنسی سے کہیں زیادہ اطلاقات رکھتے ہیں۔\n\n"
          "زیروکوائن کا مطالعہ کرکے، آپ کو اس بات کی بصیرت حاصل ہوگی کہ عوامی بلاک چین سسٹمز میں پرائیویسی کیسے حاصل کی جا سکتی ہے، شفافیت اور گمنامی کے درمیان توازن، اور ایسے سسٹمز کو نافذ کرنے میں شامل کمپیوٹیشنل چیلنجز۔\n\n"
          "یہ علم بلاک چین ڈیولپرز، سیکیورٹی ریسرچرز، اور ڈیجیٹل دور میں پرائیویسی محفوظ کرنے والی ٹیکنالوجیز پر کام کرنے والے کسی بھی شخص کے لیے ضروری ہے۔",
    },
  };

  void selectLanguage(String language) {
    selectedLanguage.value = language;
  }

  // Method to get the language code for the translator
  String getLanguageCode(String languageName) {
    switch (languageName) {
      case 'English':
        return 'en';
      case 'Urdu':
        return 'ur';
      case 'Arabic':
        return 'ar';
      case 'French':
        return 'fr';
      case 'Chinese':
        return 'zh-cn'; // Simplified Chinese
      default:
        return 'en'; // Default to English
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  bool isCategorySelected(String category) {
    return selectedCategory.value == category;
  }

  // Get translated text based on selected language
  String getTranslation(String key) {
    return translations[selectedLanguage.value]?[key] ??
        translations["English"]?[key] ??
        key;
  }

  // Get translated categories
  List<String> getTranslatedCategories() {
    return [
      getTranslation("learn_nfts"),
      getTranslation("learn_crypto"),
      getTranslation("learn_blockchain"),
      getTranslation("learn_mining"),
      getTranslation("learn_stock_market"),
    ];
  }
}
