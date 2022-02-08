Install java8 and maven:
```
sudo apt install openjdk-8-jdk
sudo apt install maven
sudo update-java-alternatives --jre-headless --set java-1.8.0-openjdk-amd64
```

Then within this directory, from the shell:
1. type `mvn verify`
2. type `mvn compile`
3. type `mvn exec:java -Dexec.mainClass="benchmarks.Benchmarks" -Dexec.args="/tmp/imgbench"` after having prepared the images

Prepare the images from the `julia/` subdirectory as described in the [main README](../README.md).
