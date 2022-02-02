Clone https://github.com/imglib/imglib2-tutorials

Install java8 and maven:
```
sudo apt install openjdk-8-jdk
sudo apt install maven
sudo update-java-alternatives --jre-headless --set java-1.8.0-openjdk-amd64
```

1. Go into the `imglib2-tutorials` directory
2. type `mvn verify`
3. type `mvn compile`
4. type `export CLASSPATH=$(mvn -q exec:exec -Dexec.classpathScope="compile" -Dexec.executable="echo" -Dexec.args="%classpath")`
5. type `java Example1a`

It should run the first example file.
