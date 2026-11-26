part of '../feed_page.dart';

// Existing resident preference terms, search, and recommendation logic.
// Interest/skill names mirror the KAISA Profile Setup screen. They are
// preferences, NOT authorization claims and not extra public profile fields.
const _kaisaInterests = <String>[
  'Environment',
  'Education',
  'Health',
  'Youth',
  'Sports',
  'Arts & Culture',
  'Technology',
  'Community Service',
  'Disaster Preparedness',
  'Livelihood',
];
const _kaisaSkills = <String>[
  'Communication',
  'Leadership',
  'Graphic Design',
  'Photography',
  'Video Editing',
  'Programming',
  'Writing',
  'Public Speaking',
  'Event Management',
  'First Aid',
];

// Common terms help connect a resident's selection with ordinary post text.
// This is explainable on-device ranking, not an ML prediction or a new RPC.
const _interestKeywords = <String, List<String>>{
  'Environment': [
    'environment',
    'ecology',
    'sustainability',
    'clean up',
    'recycling',
    'tree planting',
    'green',
    'coastal',
  ],
  'Education': [
    'education',
    'learning',
    'school',
    'tutoring',
    'student',
    'workshop',
    'seminar',
  ],
  'Health': [
    'health',
    'wellness',
    'clinic',
    'medical',
    'nutrition',
    'mental health',
    'first aid',
  ],
  'Youth': ['youth', 'students', 'young people', 'leadership', 'teen'],
  'Sports': [
    'sports',
    'basketball',
    'volleyball',
    'athletics',
    'fitness',
    'tournament',
  ],
  'Arts & Culture': [
    'art',
    'arts',
    'culture',
    'music',
    'dance',
    'painting',
    'heritage',
  ],
  'Technology': [
    'technology',
    'digital',
    'coding',
    'programming',
    'computer',
    'software',
    'it workshop',
  ],
  'Community Service': [
    'community service',
    'volunteer',
    'outreach',
    'donation',
    'charity',
    'bayanihan',
  ],
  'Disaster Preparedness': [
    'disaster',
    'preparedness',
    'emergency',
    'rescue',
    'evacuation',
    'flood',
    'safety',
  ],
  'Livelihood': [
    'livelihood',
    'employment',
    'job',
    'business',
    'entrepreneur',
    'training',
    'income',
  ],
};
const _skillKeywords = <String, List<String>>{
  'Communication': [
    'communication',
    'public relations',
    'discussion',
    'advocacy',
  ],
  'Leadership': [
    'leadership',
    'organizing',
    'facilitation',
    'community leader',
  ],
  'Graphic Design': ['graphic design', 'poster', 'design', 'layout'],
  'Photography': ['photography', 'photographer', 'photos', 'photo walk'],
  'Video Editing': ['video editing', 'film', 'videography', 'video'],
  'Programming': [
    'programming',
    'coding',
    'python',
    'software',
    'app development',
  ],
  'Writing': ['writing', 'creative writing', 'journalism', 'copywriting'],
  'Public Speaking': [
    'public speaking',
    'speech',
    'seminar',
    'host',
    'presentation',
  ],
  'Event Management': [
    'event management',
    'event planning',
    'organizer',
    'logistics',
    'coordination',
  ],
  'First Aid': ['first aid', 'cpr', 'emergency response', 'rescue'],
};

String _normalized(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

// Only a small typo tolerance. This never performs a broad user-directory query.
bool _withinOneEdit(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  if (a == b) return true;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

bool _termMatch(String text, String term) {
  final needle = _normalized(term);
  final haystack = _normalized(text);
  if (needle.isEmpty || haystack.isEmpty) return false;
  if (' $haystack '.contains(' $needle ')) return true;
  final tokens = haystack.split(' ');
  if (needle.contains(' ')) return false;
  return tokens.any(
    (word) =>
        word.startsWith(needle) ||
        (needle.length >= 5 &&
            word.length >= 5 &&
            _withinOneEdit(needle, word)),
  );
}

List<String> _readTags(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
  if (value is String) {
    final input = value.trim();
    if (input.startsWith('[')) {
      try {
        return _readTags(jsonDecode(input));
      } catch (_) {
        /* legacy CSV */
      }
    }
    return input
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
  return <String>[];
}

List<String> _postTags(Map<String, dynamic> post) => [
  ..._readTags(post['interest_tags']),
  ..._readTags(post['skill_tags']),
];

String _postTagKeywords(Map<String, dynamic> post) => [
  for (final tag in _readTags(post['interest_tags']))
    ...(_interestKeywords[tag] ?? [tag]),
  for (final tag in _readTags(post['skill_tags']))
    ...(_skillKeywords[tag] ?? [tag]),
].join(' ');

String _postCorpus(Map<String, dynamic> post) => [
  _postTags(post).join(' '),
  post['title'],
  post['body'],
  post['category'],
  post['shared_body'],
  post['shared_author_name'],
].map((value) => '${value ?? ''}').join(' ');

// All search/ranking is applied only to rows already returned by the existing
// kaisa_feed_stream RPC. Supabase visibility and RLS stay authoritative.
double _postSearchScore(Map<String, dynamic> post, String query) {
  final tokens = _normalized(query).split(' ').where((e) => e.isNotEmpty);
  if (tokens.isEmpty) return 1;
  final fields = <(String, double)>[
    (_postTags(post).join(' '), 12),
    (_postTagKeywords(post), 5),
    ('${post['author_name'] ?? ''}', 8),
    ('${post['title'] ?? ''}', 7),
    ('${post['category'] ?? ''}', 6),
    ('${post['body'] ?? ''}', 3),
    ('${post['shared_body'] ?? ''}', 2),
    ('${post['shared_author_name'] ?? ''}', 3),
  ];
  var score = 0.0;
  for (final token in tokens) {
    var weight = 0.0;
    for (final field in fields) {
      if (_termMatch(field.$1, token)) weight = math.max(weight, field.$2);
    }
    if (weight == 0) return 0; // Every word must match somewhere.
    score += weight;
  }
  final phrase = _normalized(query);
  if (phrase.isNotEmpty && _normalized(_postCorpus(post)).contains(phrase)) {
    score += 5;
  }
  return score;
}

List<String> _matchingPreferences(
  Map<String, dynamic> post,
  List<String> interests,
  List<String> skills,
) {
  final corpus = _postCorpus(post);
  return [
    for (final tag in interests)
      if (_readTags(post['interest_tags']).contains(tag) ||
          (_interestKeywords[tag] ?? [tag]).any(
            (term) => _termMatch(corpus, term),
          ))
        tag,
    for (final tag in skills)
      if (_readTags(post['skill_tags']).contains(tag) ||
          (_skillKeywords[tag] ?? [tag]).any(
            (term) => _termMatch(corpus, term),
          ))
        tag,
  ];
}

double _recommendationScore(
  Map<String, dynamic> post,
  List<String> interests,
  List<String> skills,
) {
  final published = DateTime.tryParse('${post['created_at'] ?? ''}')?.toLocal();
  final daysOld = published == null
      ? 90.0
      : math.max(0.0, DateTime.now().difference(published).inHours / 24.0);
  // Recency matters; popularity has a capped influence so newcomers are seen.
  final freshness = 24.0 / (1 + daysOld / 3.0);
  final likes = (num.tryParse('${post['likes'] ?? 0}') ?? 0).toDouble();
  final comments = (num.tryParse('${post['comments'] ?? 0}') ?? 0).toDouble();
  final engagement = math.min(
    12.0,
    2 * math.log(1 + math.max(0, likes) + 2 * math.max(0, comments)),
  );
  final relevant = _matchingPreferences(post, interests, skills);
  final interestHits = relevant.where(interests.contains).length;
  final skillHits = relevant.where(skills.contains).length;
  return freshness +
      engagement +
      math.min(32.0, interestHits * 16.0) +
      math.min(18.0, skillHits * 9.0);
}
