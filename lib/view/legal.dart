import 'package:flutter/material.dart';
import 'package:alamode_app/main.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _Section(
        '第1条（適用）',
        '本規約は、本サービスの利用に関する当方とユーザーとの一切の関係に適用されます。\n'
            '当方が本サービス内で別途定めるルールやガイドライン等は、本規約の一部を構成します。\n'
            '本規約と個別規定の内容が異なる場合は、個別規定を優先します。'),
    _Section(
        '第2条（利用登録）',
        '一部機能を利用する場合、ユーザーは当方所定の方法により利用登録を行うものとします。\n'
            '利用登録の際は、正確な情報を登録してください。\n'
            '当方は、次の場合には利用登録を拒否または取り消すことがあります。\n'
            '\n'
            '・虚偽の情報を登録した場合\n'
            '・本規約に違反した場合\n'
            '・過去に利用停止等の措置を受けたことがある場合\n'
            '・その他、当方が不適切と判断した場合\n'
            '\n'
            '当方は、ユーザーが本規約に違反した場合または本サービスの適切な運営に支障を及ぼすと判断した場合、事前の通知なく利用制限、投稿削除またはアカウント停止等の措置を講じることができます。'),
    _Section(
        '第3条（アカウント管理）',
        'ユーザーは、自己の責任においてアカウント情報を管理するものとします。\n'
            'アカウントを第三者へ貸与・譲渡・共有してはいけません。\n'
            'アカウント管理不足による損害について、当方は故意または重過失がある場合を除き責任を負いません。'),
    _Section(
        '第4条（サービス内容）',
        '本サービスでは、お菓子の記録、検索、レビューその他当方が提供する機能を利用できます。\n'
            '一部機能はログインせず利用できます。\n'
            '当方は、編集部によるおすすめ情報、お知らせその他のコンテンツを配信する場合があります。\n'
            '当方は、サービス内容を追加、変更または終了する場合があります。'),
    _Section(
        '第5条（ユーザー投稿）',
        'ユーザーは、自らが権利を有する文章および画像のみ投稿してください。\n'
            '他人の著作権、商標権、肖像権その他の権利を侵害する投稿は禁止します。\n'
            '氏名、住所、電話番号、メールアドレスその他個人情報を入力しないでください。\n'
            '当方は、法令違反、本規約違反その他不適切と判断した投稿を削除できるものとします。'),
    _Section(
        '第6条（知的財産権）',
        '本サービスに関する著作権その他の知的財産権は、当方または正当な権利者に帰属します。\n'
            'ユーザーが投稿したコンテンツの権利はユーザーまたは正当な権利者に帰属します。\n'
            'ユーザーは、当方に対し、本サービスの運営、改善、広報、研究、統計分析等に必要な範囲で投稿内容を利用する権利を無償で許諾するものとします。'),
    _Section(
        '第7条（禁止事項）',
        'ユーザーは、以下の行為を行ってはなりません。\n'
            '\n'
            '・法令または公序良俗に反する行為\n'
            '・犯罪行為または犯罪を助長する行為\n'
            '・他人の権利を侵害する行為\n'
            '・虚偽情報を投稿する行為\n'
            '・他人になりすます行為\n'
            '・本サービスの運営を妨害する行為\n'
            '・不正アクセスまたはこれを試みる行為\n'
            '・本サービスまたは第三者に不利益または損害を与える行為\n'
            '・その他当方が不適切と判断する行為'),
    _Section(
        '第8条（サービス改善およびデータ利用）',
        '当方は、サービス改善、品質向上、新機能の開発、不正利用防止その他本サービスの運営に必要な範囲で、ユーザーが登録した情報を閲覧、分析または統計的に処理する場合があります。\n'
            '前項の分析は、特定のユーザーを識別・追跡することを目的とせず、主として全体的な利用傾向および統計情報の把握を目的として行います。\n'
            '当方は、個人を特定できないよう統計的に加工または集計した情報を、研究、サービス改善、市場分析その他の目的で利用し、または第三者へ提供する場合があります。\n'
            '当方は、広告、タイアップ記事その他のプロモーションコンテンツを掲載する場合があり、法令等に従い適切に表示します。'),
    _Section(
        '第9条（免責事項）',
        '当方は、本サービスの完全性、正確性、有用性等を保証しません。\n'
            '本サービスの利用により生じた損害について、当方の故意または重過失による場合を除き責任を負いません。'),
    _Section(
        '第10条（サービスの変更・停止）',
        '1. 当方は、保守、障害対応、システム更新その他運営上必要と判断した場合、本サービスの全部または一部を変更、停止または終了することがあります。\n'
            '2. 当方は、前項によりユーザーに生じた損害について、故意または重過失がある場合を除き責任を負いません。'),
    _Section('第11条（個人情報の取扱い）', '当方は、ユーザーの個人情報を別途定める「プライバシーポリシー」に従って取り扱います。'),
    _Section(
        '第12条（利用規約の変更）',
        '1. 当方は、必要と判断した場合、本規約を変更することがあります。\n'
            '2. 変更後の規約は、本サービス内への掲載その他当方が適当と判断する方法により周知した時点から効力を生じます。'),
    _Section('第13条（準拠法・裁判管轄）',
        '本規約は日本法に準拠し、本サービスに関する紛争は東京地方裁判所を第一審の専属的合意管轄裁判所とします。'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text('利用規約',
            style: TextStyle(
                color: primary, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
/*            // 運営者情報カード
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.business, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('運営者情報',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blackDark)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('事業者名', '合同会社カイエ Cahier'),
                    _buildInfoRow('事業内容', 'モバイルアプリケーションの企画・開発・運営'),
                    _buildInfoRow('連絡先', 'メールアドレス：aaa@gmail.com'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), */
            // 利用規約カード
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 12,
                      offset: Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.description_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('利用規約',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.update,
                              color: AppColors.blackDark, size: 16),
                          SizedBox(width: 8),
                          Text('最終更新日：2026年○月○日',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blackDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '本利用規約（以下「本規約」といいます。）は、a la mode運営事務局（以下「当方」といいます。）が提供するモバイルアプリケーションおよび関連サービス「a la mode（ア・ラ・モード）」（以下「本サービス」といいます。）の利用条件を定めるものです。ユーザーは、本サービスを利用することにより、本規約に同意したものとみなします。',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.blackLight,
                          height: 1.7),
                    ),
                    const SizedBox(height: 20),
                    ..._sections.map(
                        (s) => _buildLegalSection(context, s.title, s.content)),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('以上',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.blackLight,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _Section('第1条（基本方針）',
        '当方は、ユーザーのプライバシーを尊重し、個人情報の保護に関する法令その他の関係法令を遵守するとともに、適切な管理および保護に努めます。'),
    _Section(
        '第2条（取得する情報）',
        '当方は、次の情報を取得する場合があります。\n'
            '\n'
            '【ユーザーが入力する情報】\n'
            '・メールアドレス\n'
            '・ユーザー名\n'
            '・生年月日（任意）\n'
            '・性別（任意）\n'
            '・プロフィール画像（任意）\n'
            '・お菓子情報\n'
            '・レビュー、口コミその他ユーザーが投稿した内容\n'
            '・投稿画像\n'
            '・その他ユーザーが入力した情報\n'
            '・お問い合わせ内容\n'
            '\n'
            '【自動的に取得する情報】\n'
            '本サービスの運営に必要な範囲で、アプリの利用状況・端末情報・OS情報・アプリバージョン・IPアドレス・アクセス日時・エラーログその他サービスの安定運営に必要な情報を取得する場合があります。'),
    _Section(
        '第3条（取得しない情報）',
        '1. 当方は、ユーザーが設定するパスワードを閲覧または保存しません。\n'
            '2. パスワードは認証サービスにより安全に管理されます。'),
    _Section(
        '第4条（利用目的）',
        '取得した情報は、次の目的で利用します。\n'
            '\n'
            '・本サービスの提供および運営\n'
            '・データ同期\n'
            '・アカウント管理および本人確認\n'
            '・お問い合わせへの対応\n'
            '・サービス改善および品質向上\n'
            '・新機能の開発\n'
            '・AIを活用した機能の開発および精度向上\n'
            '・不正利用の防止\n'
            '・編集部コンテンツ、お知らせその他運営上必要な情報の配信\n'
            '・利用規約違反への対応\n'
            '・法令への対応'),
    _Section(
        '第5条（サービス改善のための分析）',
        '当方は、サービス改善、品質向上、新機能の開発その他サービス運営のため、ユーザーが登録した情報を閲覧または分析する場合があります。\n'
            '分析は、特定のユーザーを識別・追跡することを目的とせず、主として利用傾向や統計情報を把握する目的で行います。'),
    _Section(
        '第6条（統計データの利用）',
        '当方は、個人を特定できないよう統計的に加工または集計した情報を、サービス改善、研究、市場分析その他の目的で利用し、または第三者へ提供する場合があります。\n'
            '第三者へ提供する情報には、個人を直接特定できる情報は含まれません。'),
    _Section(
        '第7条（第三者サービス）',
        '本サービスでは、サービス提供のため以下の第三者サービスを利用しています。\n'
            '\n'
            '・Supabase（認証・データベース・ストレージ等）\n'
            '・Google AdSense（広告配信）\n'
            '\n'
            '当該サービスでは、それぞれの提供事業者のプライバシーポリシーに基づき情報が取り扱われます。\n'
            '\n'
            'Google AdSenseを含む第三者配信事業者は、Cookieを使用して、ユーザーが本サービスや他のウェブサイトに過去にアクセスした際の情報に基づき広告を配信することがあります。ユーザーは、Googleの広告設定（https://adssettings.google.com/）からパーソナライズ広告を無効にすることができます。'),
    _Section(
        '第8条（個人情報の第三者提供）',
        '当方は、次の場合を除き、ユーザーの個人情報を本人の同意なく第三者へ提供しません。\n'
            '\n'
            '1. 法令に基づく場合\n'
            '2. 人の生命、身体または財産の保護のために必要な場合\n'
            '3. 公的機関から法令に基づく要請を受けた場合\n'
            '4. その他法令により認められる場合'),
    _Section('第9条（安全管理）',
        '当方は、取得した情報について、不正アクセス、漏えい、滅失、改ざん等を防止するため、合理的な安全管理措置を講じます。'),
    _Section(
        '第10条（国外での情報の取扱い）',
        '本サービスで利用する第三者サービスのサーバーは、日本国外に設置されている場合があります。\n'
            'ユーザーは、本サービスの利用により、必要な範囲で国外において情報が取り扱われる場合があることに同意するものとします。'),
    _Section('第11条（ユーザーの権利）', 'ユーザーは、法令に基づき、自己の個人情報について開示、訂正、削除等を請求できます。'),
    _Section(
        '第12条（未成年者の利用）',
        '未成年者は、親権者その他法定代理人の同意を得たうえで本サービスを利用するものとします。\n'
            '未成年者が利用登録を行った場合、当方は法定代理人の同意を得ているものとみなします。'),
    _Section(
        '第13条（本ポリシーの変更）',
        '当方は、法令改正またはサービス内容の変更等に応じて、本ポリシーを変更する場合があります。\n'
            '変更後の内容は、本サービス内への掲載その他適切な方法により周知した時点から効力を生じます。'),
    _Section('第14条（お問い合わせ）', '本ポリシーに関するお問い合わせは、本サービス内のお問い合わせフォームよりご連絡ください。'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text('プライバシーポリシー',
            style: TextStyle(
                color: primary, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーカード
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 12,
                      offset: Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.privacy_tip_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('プライバシーポリシー',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.update,
                              color: AppColors.blackDark, size: 16),
                          SizedBox(width: 8),
                          Text('最終更新日：2026年○月○日',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blackDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'a la mode運営事務局（以下「当方」といいます。）は、「a la mode（ア・ラ・モード）」（以下「本サービス」といいます。）におけるユーザー情報の取扱いについて、以下のとおり定めます。',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.blackLight,
                          height: 1.7),
                    ),
                    const SizedBox(height: 20),
                    ..._sections.map(
                        (s) => _buildLegalSection(context, s.title, s.content)),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('以上',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.blackLight,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget _buildLegalSection(BuildContext context, String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackDark)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyMedium, width: 1),
          ),
          child: Text(content,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.blackLight, height: 1.6)),
        ),
      ],
    ),
  );
}

class _Section {
  final String title;
  final String content;
  const _Section(this.title, this.content);
}
