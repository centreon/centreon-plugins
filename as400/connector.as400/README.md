# Tools

## Launch test

### Build

    mvn clean package

### Execute

    java \
      -DCONNECTOR_ETC=target/test-classes/ \
      -DCONNECTOR_HOME=target/test-classes/ \
      -DCONNECTOR_LOG=target/test-classes/ \
      -DCONNECTOR_TMP=target/test-classes/ \
      -jar target/centreon-as400-2.0.0-jar-with-dependencies.jar \
      --port 8091

### Test

    curl -X POST -d '{"host": "test-as400", "login": "myuser", "password": "mypass", "command": "test" }' http://127.0.0.1:8091

## References

[IBM knowledge center example](https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_72/rzahh/pcsystemstatexample.htm)
