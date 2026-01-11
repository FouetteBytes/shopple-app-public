Suggested animations to drop into this folder (filenames must match references in code):

Lottie (.json):
- hello.json           # small waving hand or greeting
- login_success.json   # subtle success check animation
- logout.json          # exit/door/sign-out animation

Rive (.riv):
- lock.riv             # small lock jiggle / pulse for password divider
- loading.riv          # compact looped loading indicator for splash

Notes:
- Place files directly in assets/animations/.
- Update pubspec.yaml already includes this folder; no extra config needed.
- Missing files are safe: OptionalAnimation silently renders nothing.
