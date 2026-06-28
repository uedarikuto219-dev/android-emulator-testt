FROM node:20-bullseye

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk wget unzip curl git cpu-checker \
    libpulse0 libgl1-mesa-glx libxml2 \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_HOME=/opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && cd ${ANDROID_HOME}/cmdline-tools \
    && wget https://google.com \
    && unzip commandlinetools-linux-11076708_latest.zip \
    && mv cmdline-tools latest \
    && rm commandlinetools-linux-11076708_latest.zip

ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools
RUN yes | sdkmanager --licenses

# 無料サーバー向けに、少し軽量なAndroid 10 (API 29) のイメージに変更してエラーを防ぎます
RUN sdkmanager "emulator" "platform-tools" "platforms;android-29" "system-images;android-29;default;x86_64"

# 16:9 ワイド画面（1920x1080）AVDの作成
RUN echo "no" | avdmanager create avd -n WideEmu -k "system-images;android-29;default;x86_64" --force
RUN AVD_CONFIG=/root/.android/avd/WideEmu.avd/config.ini && \
    echo "hw.lcd.width=1920" >> $AVD_CONFIG && \
    echo "hw.lcd.height=1080" >> $AVD_CONFIG && \
    echo "hw.lcd.density=320" >> $AVD_CONFIG && \
    echo "hw.keyboard=yes" >> $AVD_CONFIG

# ブラウザ表示用ツール（ws-scrcpy）のインストールとビルド
RUN git clone https://github.com /opt/ws-scrcpy && \
    cd /opt/ws-scrcpy && npm install && npm run dist

# 完全に画面を隠して起動するコマンド
RUN echo '#!/bin/bash\n\
emulator @WideEmu -no-window -no-audio -gpu swiftshader -no-snapshot -no-window-renderer > /var/log/emu.log 2>&1 &\n\
sleep 15\n\
cd /opt/ws-scrcpy && npm start' > /start.sh && chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]

