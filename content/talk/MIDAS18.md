+++
title = "Learning About the Norms of Teaching Practice: How Can Machine Learning Help Analyze Teachers’ Reactions to Scenarios?"
date = 2018-10-11T09:00:00-04:00  # Schedule page publish date.
draft = false

# Talk start and end times.
#   End time can optionally be hidden by prefixing the line with `#`.
time_start = 2018-10-08T12:00:00-04:00
time_end = 2018-10-08T14:00:00-04:00

# Authors. Comma separated list, e.g. `["Bob Smith", "David Jones"]`.
authors = ["Mike Ion", "Emanuele Bardelli", "Patricio Herbst"]

# Abstract and optional shortened version.
abstract = "The study of teachers’ perspectives on the work of teaching, particularly of its norms, has benefitted from teachers’ responses to multimodal scenarios where hypothesized norms are at stake. The analysis of open-ended responses to those scenarios by hand, however, is time- consuming and achieving interrater reliability for linguistics-informed coding is challenging. Using open-ended responses from a national sample of teachers, we first develop a custom word embedding, representative of teacher discussions of classroom events. A word embedding is a mapping of the set of words into a continuous (and fairly low-dimensional) vector space, where ‘semantically-similar’ words are mapped to nearby points. While other popular pre-trained word embeddings exist (e.g., Word2Vec and Glove), our custom model optimizes the embeddings in a way that is sensitive to the subject-specificity of classroom situations. We then use a convolutional neural network (CNN) to classify teachers’ responses based on their appraisal of classroom practice. Using Cohen’s Kappa, we find high inter-rater reliability (k=0.9) between the computer model and human coders, which shows promise that machine learning methods can improve and enhance our current understanding of and research on teaching."
abstract_short = ""

# Name of event and optional event URL.
event = "2018 MIDAS Symposium"
event_url = "https://midas.umich.edu/2018-symposium/"

# Location of event.
location = "University of Michigan"

# Is this a selected talk? (true/false)
selected = false

# Projects (optional).
#   Associate this talk with one or more of your projects.
#   Simply enter your project's filename without extension.
#   E.g. `projects = ["deep-learning"]` references `content/project/deep-learning.md`.
#   Otherwise, set `projects = []`.
projects = ["grip"]

# Tags (optional).
#   Set `tags = []` for no tags, or use the form `tags = ["A Tag", "Another Tag"]` for one or more tags.
tags = ["Practical Rationality", "Machine Learning"]

# Links (optional).
url_pdf = ""
url_slides = "/pdfs/2018_MIDAS_Poster.pdf"
url_video = ""
url_code = ""
url_news = ""

# Does the content use math formatting?
math = false

# Does the content use source code highlighting?
highlight = true

# Featured image
# Place your image in the `static/img/` folder and reference its filename below, e.g. `image = "example.jpg"`.
[header]
image = ""
caption = ""

+++

[News release](http://www.soe.umich.edu/news_events/news/article/emanuele_bardelli_and_michael_ions_project_awarded_most_likely_transformati/)
