class FreqQuestionModel {
  String qestion;
  String ans;
  FreqQuestionModel({required this.qestion, this.ans = ""});

  factory FreqQuestionModel.fromJson(Map<String, dynamic> json) =>
      FreqQuestionModel(
        qestion: json["question"]?.toString() ?? json["qestion"]?.toString() ?? '',
        ans: json["answer"]?.toString() ?? json["ans"]?.toString() ?? '',
      );
}
