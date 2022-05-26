import 'package:test_app/core/error/exceptions.dart';
import 'package:test_app/core/platform/network_info.dart';
import 'package:test_app/features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'package:test_app/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:test_app/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:test_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:test_app/features/number_trivia/domain/repositories/number_trivia_repository.dart';

class NumberTriviaRespositoryImpl implements NumberTriviaRepository{
  final NumberTriviaRemoteDataSource remoteDataSource;
  final NumberTriviaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NumberTriviaRespositoryImpl({required this.remoteDataSource, required this.localDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, NumberTrivia>> getConcreteNumberTrivia(int number) async{
    if(await networkInfo.isConnected){
      try {
        final remoteTrivia = await remoteDataSource.getConcreteNumberTrivia(number);
        
        localDataSource.cacheNumberTrivia(remoteTrivia);
        
        return Right(remoteTrivia);
      } on ServerException catch (e) {
        return Left(ServerFailure());
      }
    }else{
      final localTrivia = await localDataSource.getLastNumberTrivia();
      return Right(localTrivia);
    }

    
  }

  @override
  Future<Either<Failure, NumberTrivia>> getRandomNumberTrivia() {
    // TODO: implement getRandomNumberTrivia
    throw UnimplementedError();
  }
  
}