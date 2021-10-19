# Clova Face Kit webassembly example

[navigator.mediaDevices.getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)를 이용해 가져온 이미지를 Clova Face Kit을 이용해 얼굴인식 하는 방법을 소개합니다.

## 실행 방법

1. [Release Page](https://github.com/naver/clova-face-kit/releases)에서 webassembly 압축파일을 다운로드 받습니다.

2. 현재 디렉토리에 압축을 해제합니다.

   ```bash
   $ unzip clovasee-*.zip
   ```

3. 현재 디렉토리에서 webassembly content를 인식하는 web server를 시작합니다.

    ```bash
    $ npx serve .
    ```

    npx 명령어는 [node.js](https://nodejs.org/en/)를 설치하셔야 사용이 가능합니다.
    python이 익숙하신 경우:

    ```bash
    $ python3 -m http.server 8080
    ```

    도 가능합니다.

## 이미지 출처

- mask_0.png: https://commons.wikimedia.org/wiki/File:Guy_fawkes_mask_by_nacreouss-d462juf.png
- mask_1.png: https://pixabay.com/images/id-5879644/
- mask_2.png: https://pixabay.com/images/id-309396/
