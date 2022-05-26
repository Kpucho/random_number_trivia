import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/core/error/exceptions.dart';
import 'package:test_app/core/error/failures.dart';
import 'package:test_app/core/platform/network_info.dart';
import 'package:test_app/features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'package:test_app/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:test_app/features/number_trivia/data/models/number_trivia_model.dart';
import 'package:test_app/features/number_trivia/data/repositories/number_trivia_respository_impl.dart';
import 'package:test_app/features/number_trivia/domain/entities/number_trivia.dart';

class MockRemoteDataSource extends Mock implements NumberTriviaRemoteDataSource{}

class MockLocalDataSource extends Mock implements NumberTriviaLocalDataSource{}

class MockNetworkInfo extends Mock implements NetworkInfo{}

void main(){
  late NumberTriviaRespositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = NumberTriviaRespositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo
    );

  });

  group('getConcreteNumberTrivia', () {
    final tNumber = 1;
    final tNumberTriviaModel = NumberTriviaModel(text: 'Test Text', number: tNumber);
    final NumberTrivia tNumberTrivia = tNumberTriviaModel;

    test('should check if the device is online', () async{
      //arrange
      when(await mockNetworkInfo.isConnected).thenAnswer((_) => true);
      //act
      repository.getConcreteNumberTrivia(tNumber);
      //assert
      verify(await mockNetworkInfo.isConnected);
    });

    group('device is online', (){
      setUp(() async{
        when(await mockNetworkInfo.isConnected).thenAnswer((_) => true);
      });

      test('should return remote data when the call to remote data source is succesful', () async{
        //arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(tNumber)).thenAnswer((_) async => tNumberTriviaModel);
        //act
        final result = await repository.getConcreteNumberTrivia(tNumber);
        //assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber)); //return model
        expect(result, equals(Right(tNumberTrivia))); //the actual entity
      });

      test('should cache the data locally when the call to remote data source is succesful', () async{
        //arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(tNumber)).thenAnswer((_) async => tNumberTriviaModel);
        //act
        final result = await repository.getConcreteNumberTrivia(tNumber);
        //assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber)); //return model
        verify(mockLocalDataSource.cacheNumberTrivia(tNumberTriviaModel));
      });

      test('should return server failure when the call to remote data source is unsuccesful', () async{
        //arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(tNumber)).thenThrow((_) => ServerException());
        //act
        final result = await repository.getConcreteNumberTrivia(tNumber);
        //assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber)); //return model
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(ServerFailure())));
      });
    },);

    group('device is offline', () {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      test('should return last locally cached data when the cached data is present', () async{
        //arrange
        when(mockLocalDataSource.getLastNumberTrivia()).thenAnswer((_) async => tNumberTriviaModel);
        //act
        final result = await repository.getConcreteNumberTrivia(tNumber);
        //assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getLastNumberTrivia());
        expect(result, equals(Right(tNumberTrivia)));
      });
    });
  });
}

