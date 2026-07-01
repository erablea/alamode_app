import 'package:flutter/material.dart';
import 'package:alamode_app/main.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _Section('第1条（適用）',
        '1. 本規約は、ユーザーと当方との間の本サービスの利用に関する一切の関係に適用されます。\n'
        '2. 当方は、本サービスに関し、本規約のほか、ガイドラインその他の個別規定を定める場合があります。個別規定は、本規約の一部を構成するものとします。\n'
        '3. 本規約と個別規定の内容が異なる場合は、個別規定の定めが優先されます。'),
    _Section('第2条（本サービス）',
        '1. 本サービスは、お菓子に関する情報の記録、管理、閲覧その他これらに関連する機能を提供するサービスです。\n'
        '2. 本サービスは、ログインを行わずに利用できる機能と、利用登録を行うことで利用できる機能があります。\n'
        '3. ログインを行わずに登録したデータは、主として利用している端末内に保存されます。\n'
        '4. 当方は、本サービスの内容を変更、追加または終了することがあります。'),
    _Section('第3条（利用登録）',
        '1. 一部機能を利用する場合、ユーザーは当方所定の方法により利用登録を行うものとします。\n'
        '2. 登録情報は、正確かつ最新の内容としてください。\n'
        '3. 当方は、次の場合には利用登録を拒否または取り消すことがあります。\n'
        '\n'
        '・虚偽の情報を登録した場合\n'
        '・本規約に違反した場合\n'
        '・過去に利用停止等の措置を受けたことがある場合\n'
        '・その他、当方が不適切と判断した場合'),
    _Section('第4条（未成年者の利用）',
        '1. 未成年者は、親権者その他法定代理人の同意を得たうえで本サービスを利用するものとします。\n'
        '2. 未成年者が利用登録を行った場合、当方は法定代理人の同意を得ているものとみなします。'),
    _Section('第5条（アカウント管理）',
        '1. ユーザーは、自己の責任においてアカウント情報を管理するものとします。\n'
        '2. アカウントを第三者へ譲渡、貸与または共有してはなりません。\n'
        '3. アカウントの管理不十分または第三者による不正利用により生じた損害について、当方は故意または重過失がある場合を除き責任を負いません。'),
    _Section('第6条（投稿コンテンツ）',
        '1. ログインユーザーは、本サービスで提供される機能を通じて、レビュー、画像その他のコンテンツ（以下「投稿コンテンツ」といいます。）を投稿できる場合があります。\n'
        '2. ユーザーは、自ら作成したものまたは適法に利用する権利を有するコンテンツのみを投稿するものとします。\n'
        '3. 特に画像については、自ら撮影した写真または権利者から利用許諾を得た画像のみ投稿してください。\n'
        '4. 当方は、本規約または法令に違反すると判断した投稿コンテンツについて、事前の通知なく削除、非公開化または編集することがあります。'),
    _Section('第7条（知的財産権）',
        '1. 本サービスに関するプログラム、デザイン、ロゴ、編集部コンテンツその他当方が提供するコンテンツに関する著作権、商標権その他の知的財産権は、当方または正当な権利者に帰属します。\n'
        '2. ユーザーが投稿したレビュー、画像その他の投稿コンテンツの著作権は、当該ユーザーまたは正当な権利者に帰属します。\n'
        '3. ユーザーは、当方に対し、本サービスの運営、表示、検索、サービス改善、広報その他本サービスの提供に必要な範囲で、投稿コンテンツを無償で利用する非独占的な権利を許諾するものとします。\n'
        '4. 当方は、前項の目的を達成するため、投稿コンテンツについて必要最小限の編集、サイズ変更、要約その他の加工を行うことがあります。'),
    _Section('第8条（禁止事項）',
        'ユーザーは、以下の行為を行ってはなりません。\n'
        '\n'
        '1. 法令または公序良俗に反する行為\n'
        '2. 犯罪行為または犯罪を助長する行為\n'
        '3. 虚偽の情報を登録または投稿する行為\n'
        '4. 他人になりすます行為\n'
        '5. 第三者の著作権、商標権、肖像権その他の権利を侵害する行為\n'
        '6. 他人が撮影した画像や、権利者の許可なく取得した画像を投稿する行為\n'
        '7. 本サービスの運営を妨害する行為\n'
        '8. 不正アクセスまたはこれを試みる行為\n'
        '9. 本サービスまたは第三者に不利益または損害を与える行為\n'
        '10. その他、当方が不適切と判断する行為'),
    _Section('第9条（編集部コンテンツおよび広告）',
        '1. 当方は、本サービス内で編集部による記事、おすすめ情報、特集その他のコンテンツを掲載することがあります。\n'
        '2. 当方は、広告、タイアップ記事その他のプロモーションコンテンツを掲載する場合があります。\n'
        '3. 広告またはタイアップである場合には、法令等に従い適切に表示します。'),
    _Section('第10条（サービスの変更・停止）',
        '1. 当方は、保守、障害対応、システム更新その他運営上必要と判断した場合、本サービスの全部または一部を変更、停止または終了することがあります。\n'
        '2. 当方は、前項によりユーザーに生じた損害について、故意または重過失がある場合を除き責任を負いません。'),
    _Section('第11条（利用制限）',
        '当方は、ユーザーが本規約に違反した場合または本サービスの適切な運営に支障を及ぼすと判断した場合、事前の通知なく利用制限、投稿削除またはアカウント停止等の措置を講じることができます。'),
    _Section('第12条（免責事項）',
        '1. 当方は、本サービスに掲載される情報の正確性、完全性、有用性、最新性を保証するものではありません。\n'
        '2. ユーザーが投稿したレビューや評価は、投稿者個人の意見であり、当方の見解を示すものではありません。\n'
        '3. ログインを行わずに保存したデータは、端末の故障、アプリの削除その他の理由により消失する場合があります。当方は、データの保存または復旧を保証しません。\n'
        '4. 当方は、本サービスの利用または利用不能により生じた損害について、当方に故意または重過失がある場合を除き責任を負いません。'),
    _Section('第13条（個人情報の取扱い）',
        '当方は、ユーザーの個人情報を別途定める「プライバシーポリシー」に従って取り扱います。'),
    _Section('第14条（規約の変更）',
        '1. 当方は、必要と判断した場合、本規約を変更することがあります。\n'
        '2. 変更後の規約は、本サービス内への掲載その他当方が適当と判断する方法により周知した時点から効力を生じます。'),
    _Section('第15条（準拠法・管轄）',
        '1. 本規約は日本法に準拠します。\n'
        '2. 本規約の日本語版と翻訳版との間に相違がある場合は、日本語版を正文とします。\n'
        '3. 本サービスに関して紛争が生じた場合は、当方の所在地を管轄する裁判所を第一審の専属的合意管轄裁判所とします。'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text('利用規約', style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('最終更新日：2026年○月○日',
                'a la mode運営事務局（以下「当方」といいます。）が提供するモバイルアプリケーションおよび関連サービス「a la mode（ア・ラ・モード）」の利用条件を定めるものです。ユーザーは、本サービスを利用することにより、本規約に同意したものとみなされます。'),
            ..._sections.map((s) => _buildSection(context, s.title, s.content)),
            _buildFooter(),
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
    _Section('第2条（取得する情報）',
        '当方は、本サービスの提供にあたり、次の情報を取得する場合があります。\n'
        '\n'
        '【ユーザーが入力する情報】\n'
        '・メールアドレス\n'
        '・ユーザー名\n'
        '・生年月日（任意）\n'
        '・性別（任意）\n'
        '・プロフィール画像（任意）\n'
        '・レビュー、口コミその他ユーザーが投稿した内容\n'
        '・投稿画像\n'
        '・お問い合わせフォームに入力された内容\n'
        '\n'
        '【サービス利用に伴い取得する情報】\n'
        '・アプリの利用状況\n'
        '・登録したお菓子情報\n'
        '・お気に入り等の利用履歴\n'
        '・ログイン状態\n'
        '\n'
        '【自動的に取得される情報】\n'
        '本サービスの運営に必要な範囲で、端末情報・OS情報・アプリバージョン・IPアドレス・アクセス日時・エラーログその他サービスの安定運営に必要な情報を取得する場合があります。'),
    _Section('第3条（取得しない情報）',
        '1. 当方は、ユーザーが設定するパスワードを閲覧または保存しません。\n'
        '2. パスワードは認証サービスにより安全に管理されます。'),
    _Section('第4条（利用目的）',
        '取得した情報は、以下の目的で利用します。\n'
        '\n'
        '1. 本サービスの提供および運営\n'
        '2. アカウント管理および本人確認\n'
        '3. 登録データの保存・同期\n'
        '4. ユーザーからのお問い合わせへの対応\n'
        '5. サービス改善および品質向上\n'
        '6. 不正利用の防止\n'
        '7. 編集部コンテンツ、お知らせその他運営上必要な情報の配信\n'
        '8. 利用規約違反への対応\n'
        '9. 法令への対応'),
    _Section('第5条（AI技術の利用）',
        '当方は、将来的にサービス改善、検索機能の向上、おすすめ機能その他の品質向上を目的として、AI技術または機械学習技術を利用する場合があります。\n'
        '\n'
        'AI技術の利用に伴いユーザー情報の取扱いに重要な変更が生じる場合は、本ポリシーの改定その他適切な方法によりお知らせします。'),
    _Section('第6条（第三者サービス）',
        '本サービスでは、サービス提供のために以下の第三者サービスを利用しています。\n'
        '\n'
        '・Supabase（認証・データベース・ストレージ等）\n'
        '\n'
        '当該サービスでは、それぞれの事業者が定めるプライバシーポリシーに従って情報が取り扱われます。'),
    _Section('第7条（第三者提供）',
        '当方は、次の場合を除き、ユーザーの個人情報を本人の同意なく第三者へ提供しません。\n'
        '\n'
        '1. 法令に基づく場合\n'
        '2. 人の生命、身体または財産の保護のために必要な場合\n'
        '3. 公的機関から法令に基づく要請を受けた場合\n'
        '4. その他法令により認められる場合'),
    _Section('第8条（情報の管理）',
        '当方は、取得した情報の漏えい、滅失、改ざん、不正アクセス等を防止するため、合理的な安全管理措置を講じます。'),
    _Section('第9条（ユーザーの権利）',
        'ユーザーは、法令の定めるところにより、自身の個人情報について、開示、訂正、削除その他の請求を行うことができます。'),
    _Section('第10条（未成年者の利用）',
        '未成年者が本サービスを利用する場合は、保護者その他法定代理人の同意を得たうえで利用するものとします。'),
    _Section('第11条（本ポリシーの変更）',
        '当方は、法令の改正またはサービス内容の変更等に応じて、本ポリシーを変更することがあります。\n'
        '\n'
        '変更後の内容は、本サービス内への掲載その他適切な方法により周知した時点から効力を生じます。'),
    _Section('第12条（お問い合わせ）',
        '本ポリシーに関するお問い合わせは、本サービス内のお問い合わせフォームまたは当方が別途指定する連絡先までご連絡ください。'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text('プライバシーポリシー', style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w600)),
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
                          child: const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('プライバシーポリシー',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blackDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.update, color: AppColors.blackDark, size: 16),
                          SizedBox(width: 8),
                          Text('最終更新日：2026年○月○日',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blackDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'a la mode運営事務局（以下「当方」といいます。）は、モバイルアプリケーションおよび関連サービス「a la mode（ア・ラ・モード）」におけるユーザー情報の取扱いについて、以下のとおり定めます。',
                      style: TextStyle(fontSize: 14, color: AppColors.blackLight, height: 1.7),
                    ),
                    const SizedBox(height: 20),
                    ..._sections.map((s) => _buildPolicySection(context, s.title, s.content)),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('以上',
                          style: TextStyle(fontSize: 14, color: AppColors.blackLight, fontWeight: FontWeight.w500)),
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

Widget _buildPolicySection(BuildContext context, String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blackDark)),
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
              style: const TextStyle(fontSize: 13, color: AppColors.blackLight, height: 1.6)),
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

Widget _buildHeader(String date, String intro) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(date, style: const TextStyle(fontSize: 12, color: AppColors.blackLight, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(intro, style: const TextStyle(fontSize: 13, color: AppColors.blackDark, height: 1.6)),
      ],
    ),
  );
}

Widget _buildSection(BuildContext context, String title, String content) {
  final primary = Theme.of(context).primaryColor;
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blackDark)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyMedium),
          ),
          child: Text(content, style: const TextStyle(fontSize: 13, color: AppColors.blackLight, height: 1.7)),
        ),
      ],
    ),
  );
}

Widget _buildFooter() {
  return Container(
    margin: const EdgeInsets.only(top: 4, bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.greyLight,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text('以上', style: TextStyle(fontSize: 13, color: AppColors.blackLight, fontWeight: FontWeight.w500)),
    ),
  );
}
