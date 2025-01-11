import 'package:flutter/material.dart';
import 'dart:math';
import 'app_theme.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final (greeting, motivation, accentColorHex) = _getTimeBasedContent(hour);
    final accentColor = Color(int.parse(accentColorHex.substring(1, 7), radix: 16) + 0xFF000000);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isWideScreen = screenWidth > AppTheme.tabletBreakpoint;

        return AnimatedContainer(
          duration: AppTheme.normalAnimation,
          width: screenWidth,
          margin: EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingSmall,
          ),
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                accentColor.withOpacity(0.2),
              ],
              stops: const [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Ortaya hizalama
            children: [
              _buildGreetingText(greeting, isWideScreen),
              SizedBox(height: AppTheme.paddingSmall),
              _buildMotivationText(motivation, isWideScreen),
              SizedBox(height: AppTheme.paddingSmall),
              _buildMotivationQuote(isWideScreen, accentColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreetingText(String greeting, bool isWideScreen) {
    return TweenAnimationBuilder<double>(
      duration: AppTheme.quickAnimation,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Text(
              greeting,
              textAlign: TextAlign.center, // Ortaya hizalama
              style: isWideScreen
                  ? AppTheme.headingLarge
                  : AppTheme.headingMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationText(String motivation, bool isWideScreen) {
    return TweenAnimationBuilder<double>(
      duration: AppTheme.quickAnimation,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.paddingSmall,
              ),
              child: Text(
                motivation,
                textAlign: TextAlign.center, // Ortaya hizalama
                style:
                (isWideScreen ? AppTheme.bodyLarge : AppTheme.bodyMedium)
                    .copyWith(color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationQuote(bool isWideScreen, Color accentColor) {
    final quotes = [
      '"Sınırlarını zorla, limitlerini aş." - Usain Bolt',
      '"Başarı bir yolculuktur, varış noktası değil." - Arthur Ashe',
      '"Mükemmellik bir alışkanlıktır." - Aristoteles',
      '"Her engel, kararlılığımı güçlendirir." - Leonardo da Vinci',
      '"Başarı, hazırlık fırsatla buluştuğunda gelir." - Zig Ziglar',
      '"Hayatta en büyük zafer, hiç düşmemek değil, her düştüğünde ayağa kalkmaktır." - Nelson Mandela',
      '"Kendini geliştirmek, kendine yapabileceğin en büyük yatırımdır." - Benjamin Franklin',
      '"Büyük zihinler fikirleri tartışır, orta zihinler olayları tartışır, küçük zihinler ise insanları tartışır." - Eleanor Roosevelt',
      '"Hayatınızı dönüştürmek için, düşüncelerinizi dönüştürün." - Wayne Dyer',
      '"Başarı son bir kez daha deneme cesaretinde gizlidir." - Walt Disney',
      '"Hayat bisiklet sürmek gibidir. Dengenizi korumak için hareket etmeye devam etmelisiniz." - Albert Einstein',
      '"Başkalarının senin hakkında ne düşündüğü, senin kim olduğundan daha az önemlidir." - Marcus Aurelius',
      '"Hayallerinizin sınırı yoksa, başarınızın da sınırı yoktur." - Michael Phelps',
      '"Kendinizi keşfetmek, hayatın en büyük yolculuğudur." - Plato',
      '"Başarı, başarısızlıktan başarısızlığa umudunu kaybetmeden yolculuk etmektir." - Winston Churchill',
      '"Dünyayı değiştirmek istiyorsan, önce kendini değiştir." - Mahatma Gandhi',
      '"Hayatta en değerli olan şey, her gün biraz daha bilge olmaktır." - Sokrates',
      '"Zorluklar, güçlü insanlar yaratır." - Robert H. Schuller',
      '"Başarı, küçük çabaların sürekli tekrarlanmasıdır." - Robert Collier',
      '"Kendinize inanın, tüm şüphelere rağmen. Yapabileceğinizi bilin ve o zaman doğal olarak yapabilme fırsatı doğacaktır." - Mahatma Gandhi',
      '"Düşünceleriniz geleceğinizi şekillendirir. Olmak istediğiniz kişi gibi düşünün." - Oprah Winfrey',
      '"En büyük zaferimiz hiç düşmemek değil; her düştüğümüzde tekrar ayağa kalkmaktır." - Konfüçyüs',
      '"Bir hayali gerçekleştirmek için ilk adım onu hayal etmektir." - Walt Disney',
      '"Başarı cesaret ister. Korkularınızı aşın ve harekete geçin!" - Tony Robbins',
      '"Küçük adımlar büyük sonuçlar doğurur. Her gün bir adım atın!" - Lao Tzu',
      '"Yapabileceğinize inandığınızda başarmak kaçınılmazdır." - Henry Ford',
      '"Hayatınızın her anında öğrenmeye açık olun. Bilgi güçtür!" - Francis Bacon',
      '"Zamanınız sınırlı; bu yüzden başkalarının hayatını yaşamayın!" - Steve Jobs',
      '"Başarısızlık bir son değil; başarıya giden yolda bir adımdır." - Thomas Edison',
      '"Kendi hikayenizin kahramanı olun. Başkalarının yazdığı senaryolara göre yaşamayın!" - J.K. Rowling'
    ];

    final randomQuote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding:
      EdgeInsets.all(isWideScreen ? AppTheme.paddingMedium : AppTheme.paddingSmall),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.2),
            accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius:
        BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color:
            accentColor.withOpacity(0.1),
            blurRadius:
            8,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child:
      Column(
          crossAxisAlignment:
          CrossAxisAlignment.center, // Ortaya hizalama
          children:
          [
            Icon(Icons.format_quote,
                color:
                accentColor.withOpacity(0.3),
                size:
                isWideScreen ? 32 : 24),
            SizedBox(height:
            AppTheme.paddingSmall),
            Text(randomQuote,
                textAlign:
                TextAlign.center, // Ortaya hizalama
                style:
                (isWideScreen ? AppTheme.bodyMedium : AppTheme.bodySmall)
                    .copyWith(fontStyle:
                FontStyle.italic,
                    color:
                    Colors.white.withOpacity(0.9))),
          ]),
    );
  }

  (String, String, String) _getTimeBasedContent(int hour) {
    final random = Random();

    if (hour < 5) {
      final messages = [
        ('Gece Düşünürü', 'Sessizlikte kendini keşfet', '#6A0572'),
        ('Yıldızların Altında', 'Her zorluk bir fırsattır', '#FF6347'),
        ('Gece Sefası', 'Karanlıkta bile umut vardır', '#8B008B'),
        ('Derin Düşünceler', 'Kendini keşfetmek bir yolculuktur', '#483D8B'),
      ];
      return messages[random.nextInt(messages.length)];
    } else if (hour < 10) {
      final messages = [
        ('Günaydın', 'Bugün kendini sevmeyi unutma', '#32CD32'),
        ('Yeni Başlangıç', 'Her gün yeni bir fırsat sunar', '#FFD700'),
        ('Sabah Enerjisi', 'Küçük adımlar büyük değişimler yaratır', '#FF4500'),
        ('Şafak Vakti', 'Yeni bir gün, yeni bir sen', '#00CED1'),
      ];
      return messages[random.nextInt(messages.length)];
    } else if (hour < 14) {
      final messages = [
        ('Öğle Arası', 'Kendine zaman ayır ve yenilen', '#00BFFF'),
        ('Mola Zamanı', 'Dinlenmek de üretmektir', '#FF8C00'),
        ('İkinci Dalga', 'Yenilenmek için asla geç değil', '#FF6347'),
        ('Verimli Saatler', 'Potansiyelini keşfet!', '#4682B4'),
      ];
      return messages[random.nextInt(messages.length)];
    } else if (hour < 17) {
      final messages = [
        ('Güneş Batıyor', 'Her an değerlidir, anı yaşa!', '#FF4500'),
        ('Gün Ortası', 'Sevgiyle yaklaş, sevgiyle uzaklaş', '#32CD32'),
        ('Azim Zamanı', 'Zorluklar seni güçlendirir', '#8A2BE2'),
        ('Başarı Yolu', 'Sabırla devam et, sonuçlar gelecek!', '#FFD700'),
      ];
      return messages[random.nextInt(messages.length)];
    } else if (hour < 20) {
      final messages = [
        ('Akşam Üzeri', 'Günün kazanımlarını kutla!', '#6A0572'),
        ('Gün Batımı', 'Her gün bir armağandır, tadını çıkar!', '#FF6347'),
        ('Alacakaranlık', 'Huzuru içinde ara ve bul.', '#483D8B'),
        ('Dinlenme Zamanı', 'Yarın için enerji topla.', '#FFA07A'),
      ];
      return messages[random.nextInt(messages.length)];
    } else {
      final messages = [
        ('Gece Başlıyor', 'Kendine şefkat göster ve dinlen.', '#6A0572'),
        ('Yıldızlar Altında', 'Hayallerin sınırı yok.', '#FF4500'),
        ('Gece Sohbeti', 'İç sesini dinlemenin tam zamanı.', '#8B008B'),
        ('Derin Gece Düşünceleri', 'Kendini tanımak en büyük yolculuktur.', '#483D8B'),
      ];
      return messages[random.nextInt(messages.length)];
    }
  }
}
