package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import cn.homeledger.support.ApiTestBase;

/**
 * §4.3.1 / §4.4.1 档案照片链（S10）：上传 → 鉴权读取 → 替换 → 清除，以及「照片是家庭私密数据」
 * 这条主线的越权测试。照片不走统一响应体、读取端是 {@code <img>}，所以读图断言在二进制上。
 */
class PhotoFlowIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000011";

	private static final String PHONE_B = "13800000012";

	private static final String PHONE_OTHER = "13800000013";

	private static final String PHONE_ALONE = "13800000014";

	@BeforeEach
	void cleanPhotoDir() {
		clearPhotoFiles();
	}

	@Test
	@DisplayName("上传猫照片：响应带 /photos/<uuid>.jpg 相对路径，文件落盘，读图端点原样回传同一份字节")
	void catPhotoRoundTrip() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		byte[] bytes = jpegBytes();

		Call uploaded = uploadMultipart(CATS + "/" + catId + "/photo", owner.accessToken(), "file", "meow.jpg",
				"image/jpeg", bytes);
		assertThat(uploaded.status()).isEqualTo(200);
		assertThat(uploaded.code()).isEqualTo("OK");
		String photoUrl = uploaded.data().path("photoUrl").asText();
		assertThat(photoUrl).matches("/photos/[0-9a-f]{32}\\.jpg");

		assertThat(fileOnDisk(photoUrl)).as("落盘的文件确实存在").isTrue();
		assertThat(jdbcTemplate.queryForObject("SELECT photo_url FROM cat WHERE id = ?", String.class, catId))
			.as("库里存的是相对路径").isEqualTo(photoUrl);
		assertThat(getJson(CATS + "?includeArchived=true", owner.accessToken()).data().get(0).path("photoUrl").asText())
			.as("清单响应也要带出来，不然列表页显示不了照片").isEqualTo(photoUrl);

		BinaryCall read = getBytes(PHOTOS + "/" + fileNameOf(photoUrl), Map.of(), owner.accessToken());
		assertThat(read.status()).isEqualTo(200);
		assertThat(read.contentType()).as("Content-Type 按扩展名给，区分格式").startsWith("image/jpeg");
		assertThat(read.body()).as("读图是原样回传，不是重新编码").isEqualTo(bytes);
	}

	@Test
	@DisplayName("宝宝照片同一条链：PNG 上传、image/png 读回")
	void babyPhotoRoundTrip() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner, "小宝");
		byte[] bytes = pngBytes();

		Call uploaded = uploadMultipart(BABIES + "/" + babyId + "/photo", owner.accessToken(), "file", "baby.png",
				"image/png", bytes);
		assertThat(uploaded.code()).isEqualTo("OK");
		String photoUrl = uploaded.data().path("photoUrl").asText();
		assertThat(photoUrl).endsWith(".png");

		BinaryCall read = getBytes(PHOTOS + "/" + fileNameOf(photoUrl), Map.of(), owner.accessToken());
		assertThat(read.status()).isEqualTo(200);
		assertThat(read.contentType()).startsWith("image/png");
		assertThat(read.body()).isEqualTo(bytes);
	}

	@Test
	@DisplayName("家庭成员可以读照片：成员身份即可，不要求是上传者本人")
	void memberOfSameFamilyCanReadThePhoto() throws Exception {
		Account owner = register(PHONE_A, "张三");
		FamilyHandle family = createFamily(owner, "张家");
		Account member = register(PHONE_B, "李四");
		inviteAndJoin(owner, member);
		long catId = createCat(owner, "奶糖");
		String photoUrl = uploadAndUrl(owner, catId);

		BinaryCall read = getBytes(PHOTOS + "/" + fileNameOf(photoUrl), Map.of(), member.accessToken());
		assertThat(read.status()).as("档案全家共享，照片也一样").isEqualTo(200);
	}

	@Test
	@DisplayName("换照片把旧文件删掉：photo_url 指向新文件，旧文件不再留在磁盘上")
	void replacingPhotoDeletesTheOldFile() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		String first = uploadAndUrl(owner, catId);
		String second = uploadBytes(owner, catId, jpegBytes()).data().path("photoUrl").asText();

		assertThat(second).isNotEqualTo(first);
		assertThat(fileOnDisk(first)).as("旧文件不再被引用，落盘即删——否则换一张图磁盘涨两份").isFalse();
		assertThat(fileOnDisk(second)).isTrue();
		assertThat(jdbcTemplate.queryForObject("SELECT photo_url FROM cat WHERE id = ?", String.class, catId))
			.isEqualTo(second);
	}

	@Test
	@DisplayName("清照片：photo_url 置空、文件删除，读图端点随之 404")
	void clearingPhotoRemovesUrlAndFile() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		String photoUrl = uploadAndUrl(owner, catId);

		Call cleared = deleteNoBody(CATS + "/" + catId + "/photo", owner.accessToken());
		assertThat(cleared.code()).isEqualTo("OK");
		assertThat(cleared.data().path("photoUrl").isNull()).as("清完回的是「无照片」").isTrue();
		assertThat(fileOnDisk(photoUrl)).isFalse();
		assertThat(getBytes(PHOTOS + "/" + fileNameOf(photoUrl), Map.of(), owner.accessToken()).status())
			.as("引用没了，文件也没了，读图就该 404").isEqualTo(404);
	}

	@Test
	@DisplayName("照片是家庭私密数据：别家按 fileId 读不到，给别家的档案传照片也 404，本家数据一个字节不动")
	void photoIsPrivateToTheFamily() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		String photoUrl = uploadAndUrl(owner, catId);
		Account outsider = registerWithFamily(PHONE_OTHER, "王五");

		BinaryCall read = getBytes(PHOTOS + "/" + fileNameOf(photoUrl), Map.of(), outsider.accessToken());
		assertThat(read.status()).as("知道文件名的外人按 id 读，也必须撞 404（§4.3.1 的鉴权在服务端）")
			.isEqualTo(404);
		assertThat(uploadMultipart(CATS + "/" + catId + "/photo", outsider.accessToken(), "file", "x.jpg",
				"image/jpeg", jpegBytes()).code()).isEqualTo("RESOURCE_NOT_FOUND");

		assertThat(jdbcTemplate.queryForObject("SELECT photo_url FROM cat WHERE id = ?", String.class, catId))
			.as("被拒的两次都没改动本家数据").isEqualTo(photoUrl);
		assertThat(fileOnDisk(photoUrl)).isTrue();
	}

	@Test
	@DisplayName("库里没有行引用的 fileId、不合法的文件名一律 404：孤儿文件与越权同一说法")
	void unreferencedOrIllegalFileIdIsNotFound() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");

		BinaryCall orphan = getBytes(PHOTOS + "/" + "00000000000000000000000000000000.jpg", Map.of(),
				owner.accessToken());
		assertThat(orphan.status()).isEqualTo(404);

		BinaryCall illegal = getBytes(PHOTOS + "/not-a-uuid.jpg", Map.of(), owner.accessToken());
		assertThat(illegal.status()).as("文件名不过 SAFE_FILE 白名单，读图端直接当不存在").isEqualTo(404);
	}

	@Test
	@DisplayName("空文件 / 超 5 MB / 魔数不认识都拒收；Content-Type 说了不算，文件尾格才算")
	void invalidUploadsAreRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long catId = createCat(owner, "奶糖");
		String path = CATS + "/" + catId + "/photo";

		Call empty = uploadMultipart(path, owner.accessToken(), "file", "e.jpg", "image/jpeg", new byte[0]);
		assertThat(empty.code()).as("空文件按「没收到」拒绝而不是存一个 0 字节文件").isEqualTo("BAD_REQUEST");
		assertThat(empty.message()).contains("没有收到");

		byte[] oversized = new byte[5 * 1024 * 1024 + 1];
		oversized[0] = (byte) 0xFF;
		oversized[1] = (byte) 0xD8;
		oversized[2] = (byte) 0xFF;
		Call tooBig = uploadMultipart(path, owner.accessToken(), "file", "big.jpg", "image/jpeg", oversized);
		assertThat(tooBig.code()).isEqualTo("BAD_REQUEST");
		assertThat(tooBig.message()).contains("5 MB");

		// 声称 image/jpeg 但前三个字节不是 JPEG 魔数：格式判定信魔数不信头里的这句话
		Call fake = uploadMultipart(path, owner.accessToken(), "file", "fake.jpg", "image/jpeg", new byte[] { 1, 2, 3 });
		assertThat(fake.code()).isEqualTo("BAD_REQUEST");
		assertThat(fake.message()).contains("只支持");

		assertThat(jdbcTemplate.queryForObject("SELECT photo_url FROM cat WHERE id = ?", String.class, catId))
			.as("三次被拒都不写 photo_url").isNull();
	}

	@Test
	@DisplayName("没有家庭的账号传照片与读图都被拦：NO_FAMILY / 403，而不是让哨兵值查出一份空")
	void photoEndpointsRequireAFamily() throws Exception {
		Account lonely = register(PHONE_ALONE, "赵六");

		Call upload = uploadMultipart(CATS + "/1/photo", lonely.accessToken(), "file", "x.jpg", "image/jpeg",
				jpegBytes());
		assertThat(upload.code()).as("无家庭的账号先被 @RequiresFamily 拦下，不会去查那只猫在不在")
			.isEqualTo("NO_FAMILY");
		assertThat(getBytes(PHOTOS + "/" + "00000000000000000000000000000000.jpg", Map.of(), lonely.accessToken())
			.status()).isEqualTo(403);
	}

	// ---- 辅助 ----

	/** 最小合法 JPEG 魔数 + 填充字节。读取端只验魔数并原样回传，不必是能解码的真图。 */
	private static byte[] jpegBytes() {
		byte[] bytes = new byte[64];
		bytes[0] = (byte) 0xFF;
		bytes[1] = (byte) 0xD8;
		bytes[2] = (byte) 0xFF;
		for (int i = 3; i < bytes.length; i++) {
			bytes[i] = (byte) (i * 31);
		}
		return bytes;
	}

	private static byte[] pngBytes() {
		byte[] bytes = new byte[16];
		System.arraycopy(new byte[] { (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, 0, bytes, 0, 8);
		for (int i = 8; i < bytes.length; i++) {
			bytes[i] = (byte) (i * 7);
		}
		return bytes;
	}

	private long createCat(Account account, String name) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", "FEMALE");
		body.put("birthday", "2024-05-20");
		body.put("birthdayEstimated", false);
		body.put("neutered", "YES");
		Call call = postJson(CATS, body, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private long createBaby(Account account, String name) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("name", name);
		body.put("gender", "FEMALE");
		body.put("birthDate", "2024-05-20");
		Call call = postJson(BABIES, body, account.accessToken());
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("id").asLong();
	}

	private Call uploadBytes(Account account, long catId, byte[] bytes) throws Exception {
		return uploadMultipart(CATS + "/" + catId + "/photo", account.accessToken(), "file", "p.jpg", "image/jpeg",
				bytes);
	}

	private String uploadAndUrl(Account account, long catId) throws Exception {
		Call call = uploadBytes(account, catId, jpegBytes());
		assertThat(call.code()).isEqualTo("OK");
		return call.data().path("photoUrl").asText();
	}

	private String fileNameOf(String photoUrl) {
		return photoUrl.substring("/photos/".length());
	}

	private boolean fileOnDisk(String photoUrl) {
		Path dir = this.photoProperties.dir().toAbsolutePath().normalize();
		return Files.isRegularFile(dir.resolve(fileNameOf(photoUrl)));
	}

}