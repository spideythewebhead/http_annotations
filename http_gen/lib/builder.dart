library http_gen.builder;

import 'package:build/build.dart';
import 'package:http_gen/src/http_api_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder httpApiBuilder(BuilderOptions options) => PartBuilder([HttpApiGenerator()], '.http.dart');
