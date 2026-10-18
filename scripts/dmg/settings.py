"""Deterministic Finder layout; no Finder or AppleScript session is required."""
from pathlib import Path

staging = Path(defines['staging'])
format = 'UDZO'
filesystem = 'HFS+'
files = [str(staging / 'Plupo.app'), str(staging / 'LICENSE.txt'), str(staging / 'Read Me.txt')]
symlinks = {'Applications': '/Applications'}
hide = ['LICENSE.txt', 'Read Me.txt']
hide_extensions = ['Plupo.app']
background = str(Path('scripts/dmg/background.tiff').resolve())
icon = str(staging / 'Plupo.app' / 'Contents' / 'Resources' / 'AppIcon.icns')
window_rect = ((160, 160), (600, 412))
default_view = 'icon-view'
show_toolbar = False
show_status_bar = False
show_tab_view = False
show_pathbar = False
show_sidebar = False
arrange_by = None
icon_size = 112
text_size = 14
label_pos = 'bottom'
icon_locations = {'Plupo.app': (155, 197), 'Applications': (445, 197)}
