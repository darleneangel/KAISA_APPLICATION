"""Run from KAISA project root. Requires Pillow. Downloads real source photos.
1920x1080 output is a crop/resample, not a guarantee of native HD detail.
Obtain permission from the source before public deployment.
"""
from pathlib import Path
from io import BytesIO
from urllib.request import Request, urlopen
from PIL import Image, ImageOps
import sys

PHOTOS = [('unlad_pier.jpg', 'https://thecaviterising.com/wp-content/uploads/2023/09/Photo-1-Article-180-091623.png', 'https://thecaviterising.com/wp-content/uploads/2023/09/Photo-1-Article-180-091623-1024x576.png'), ('corregidor_2025.jpg', 'https://thecaviterising.com/wp-content/uploads/2025/06/Photo-8-Article-143-060625.jpg', 'https://thecaviterising.com/wp-content/uploads/2025/06/Photo-8-Article-143-060625-1024x683.jpg'), ('regada_foam_2025.jpg', 'https://media.assettype.com/tribune%2F2025-07-20%2Fq9frrgh4%2FRevelers-enjoying-a-foam-party-Photo-by-Roel-Hoang-Manipon.jpg'), ('regada_2025.jpg', 'https://media.assettype.com/tribune%2F2025-07-20%2Fg6tgw5si%2FFirefighters-drenching-attendees-with-cool-water-Photo-by-Roel-Hoang-Manipon.jpg')]

def main():
    if not Path('pubspec.yaml').is_file():
        sys.exit('Run this script from the Flutter project root (pubspec.yaml).')
    target = Path('assets/images/cavite')
    target.mkdir(parents=True, exist_ok=True)
    failed = []
    for name, *urls in PHOTOS:
        for url in urls:
            try:
                with urlopen(Request(url, headers={'User-Agent': 'Mozilla/5.0'}), timeout=35) as response:
                    data = response.read(40_000_001)
                if len(data) > 40_000_000:
                    raise ValueError('Image too large')
                with Image.open(BytesIO(data)) as raw:
                    im = ImageOps.exif_transpose(raw).convert('RGB')
                w, h = im.size
                native = w >= 1920 and h >= 1080
                out = ImageOps.fit(im, (1920, 1080), Image.Resampling.LANCZOS)
                temp = target / (name + '.tmp')
                out.save(temp, format='JPEG', quality=94, optimize=True)
                temp.replace(target / name)
                print(f'{name}: source {w}x{h}; output 1920x1080; ' + ('native size sufficient' if native else 'UPSCALED: original lacks full HD detail'))
                break
            except Exception as error:
                print(f'{name}: {error}; trying next source')
        else:
            failed.append(name)
    if failed:
        sys.exit('Failed to download: ' + ', '.join(failed) + '. Existing assets were not deleted.')
    print('Done. Register assets/images/cavite/ in pubspec.yaml.')

if __name__ == '__main__':
    main()
