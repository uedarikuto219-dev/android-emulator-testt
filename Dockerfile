FROM budtmo/docker-android:emulator_10

EXPOSE 6080 5554 5555

CMD ["/vnc.sh"]



