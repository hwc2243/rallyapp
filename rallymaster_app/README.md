# RallyMaster App

Flutter application for designing road rallies. It currently provides the RallyMaster welcome screen and home-screen launcher icon.

## Build and run

```sh
./tool/flutterw run
```

Use `./tool/flutterw` instead of invoking `flutter` directly for commands that
compile the application. It regenerates the ServiceBuilder Flutter DTOs from
[`rallymaster_server/src/main/resources/service.xml`](../rallymaster_server/src/main/resources/service.xml)
before delegating all arguments to Flutter. For example:

```sh
./tool/flutterw build ios
./tool/flutterw build appbundle
./tool/flutterw test
```

The generated DTO source is written to `lib/models`. The wrapper uses the
`flutter-client-generation` Maven profile, so regular RallyMaster server builds
do not modify the Flutter project.
